const { BN } = require('@openzeppelin/test-helpers/src/setup');
const { expect } = require('chai');

const IERC20 = artifacts.require('IERC20');
const KyberMooniswapReserve = artifacts.require('KyberMooniswapReserve.sol');

const ethAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const ethDecimals = new BN(18);
const usdtDecimals = new BN(6);

let usdtToken;
let reserve;

contract('KyberMooniswapReserve', function (accounts) {
    // set kybetNetwork as accounts[0] for permission to trade
    const kyberNetwork = accounts[0];
    before('set up', async () => {
        usdtToken = await IERC20.at('0xdac17f958d2ee523a2206206994597c13d831ec7');
        reserve = await KyberMooniswapReserve.new(kyberNetwork);
    });

    it('test swap eth to usdt', async () => {
        const ethWei = new BN(10).pow(new BN(18));
        const rate = await reserve.getConversionRate(
            ethAddress,
            usdtToken.address,
            ethWei,
            new BN(0),
        );
        const expectedDstQty = calcDstQty(ethWei, ethDecimals, usdtDecimals, rate);
        const oldBalance = await usdtToken.balanceOf(kyberNetwork);
        await reserve.trade(ethAddress, ethWei, usdtToken.address, kyberNetwork, rate, true, {
            value: ethWei,
        });
        const newBalance = await usdtToken.balanceOf(kyberNetwork);
        expect(expectedDstQty).to.be.bignumber.most(newBalance.sub(oldBalance));
    });

    it('test swap usdt to eth', async () => {
        const tokenTwei = await usdtToken.balanceOf(kyberNetwork);
        const rate = await reserve.getConversionRate(
            usdtToken.address,
            ethAddress,
            tokenTwei,
            new BN(0),
        );
        // approve from network to reserve
        await usdtToken.approve(reserve.address, tokenTwei, { from: kyberNetwork });
        const expectedDstQty = calcDstQty(tokenTwei, usdtDecimals, ethDecimals, rate);
        const oldBalance = web3.utils.toBN(await web3.eth.getBalance(kyberNetwork));
        await reserve.trade(usdtToken.address, tokenTwei, ethAddress, kyberNetwork, rate, true, {
            gasPrice: new BN(0),
        });
        // check new balance as expected
        const newBalance = await web3.utils.toBN(await web3.eth.getBalance(kyberNetwork));
        expect(expectedDstQty).to.be.bignumber.most(newBalance.sub(oldBalance));
    });
});

function calcDstQty (srcQty, srcDecimals, dstDecimals, rate) {
    srcQty = new BN(srcQty);
    srcDecimals = new BN(srcDecimals);
    dstDecimals = new BN(dstDecimals);
    rate = new BN(rate);
    const precisionUnits = new BN(10).pow(new BN(18));
    if (dstDecimals.gte(srcDecimals)) {
        return srcQty
            .mul(rate)
            .mul(new BN(10).pow(new BN(dstDecimals.sub(srcDecimals))))
            .div(precisionUnits);
    } else {
        return srcQty
            .mul(rate)
            .div(precisionUnits.mul(new BN(10).pow(new BN(srcDecimals.sub(dstDecimals)))));
    }
}
