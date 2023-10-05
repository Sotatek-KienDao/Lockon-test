// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IStargateComposer.sol";
import "./util/BytesLib.sol";
import "./util/SafeCall.sol";

contract LockonSourceContract is Ownable {
    using BytesLib for bytes;
    using SafeCall for address;
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("mint(address,uint256)")));
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _swapStatus = _NOT_ENTERED;

    address public dstContractAddress;
    address public uniswapRouterAddress;
    address public USDC;

    struct PoolInfo {
        address token;
        address poolAddress;
        uint256 convertRate;
    }

    modifier nonSwapReentrant() {
        require(_swapStatus != _ENTERED, "LOCKON: reentrant call");
        _swapStatus = _ENTERED;
        _;
        _swapStatus = _NOT_ENTERED;
    }

    event CachedSwapSaved(
        uint16 chainId,
        bytes srcAddress,
        uint256 nonce,
        bytes reason
    );

    event ComposedTokenTransferFailed(
        address token,
        address intendedReceiver,
        uint amountLD
    );

    struct SwapAmount {
        uint256 amountLD; // the amount, in Local Decimals, to be swapped
        uint256 minAmountLD; // the minimum amount accepted out on destination
    }

    constructor(
        address _dstContractAddress,
        address _uniswapRouterAddress,
        address _USDC
    ) {
        stargateBridge = IStargateBridge(_stargateBridge);
        stargateRouter = IStargateRouter(_stargateRouter);
        wethPoolId = _wethPoolId;
        setStargateEthVaults(_wethPoolId, _stargateEthVault);

        (bool success, bytes memory data) = _stargateRouter.staticcall(
            abi.encodeWithSignature("factory()")
        );
        require(success, "Stargate: invalid factory address");
        factory = abi.decode(data, (address));
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable override nonSwapReentrant {
        bytes memory newPayload;
        bytes memory peer;
        if (_payload.length > 0) {
            newPayload = _buildPayload(_to, _payload);
            peer = _getPeer(_dstChainId);

            // overhead for calling composer's sgReceive()
            _lzTxParams.dstGasForCall += dstGasReserve + transferOverhead;
        } else {
            newPayload = "";
            peer = _to;
        }

        if (isEthPool(_srcPoolId)) {
            require(
                msg.value > _amountLD,
                "Stargate: msg.value must be > _swapAmount.amountLD"
            );
            IStargateEthVault(stargateEthVaults[_srcPoolId]).deposit{
                value: _amountLD
            }();
            IStargateEthVault(stargateEthVaults[_srcPoolId]).approve(
                address(stargateRouter),
                _amountLD
            );
        } else {
            PoolInfo memory poolInfo = _getPoolInfo(_srcPoolId);
            // remove dust
            if (poolInfo.convertRate > 1)
                _amountLD = _amountLD.div(poolInfo.convertRate).mul(
                    poolInfo.convertRate
                );
            // transfer token to this contract
            IERC20(poolInfo.token).safeTransferFrom(
                msg.sender,
                address(this),
                _amountLD
            );
        }

        stargateRouter.swap{
            value: isEthPool(_srcPoolId) ? msg.value - _amountLD : msg.value
        }(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            _refundAddress,
            _amountLD,
            _minAmountLD,
            _lzTxParams,
            peer, // swap the to address with the peer address
            newPayload
        );
    }

    function refundETH() internal payable override {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }
}
