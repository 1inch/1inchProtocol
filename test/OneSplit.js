const { BN, ether, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const assert = require('assert');

const OneSplitView = artifacts.require('OneSplitView');
const OneSplitViewWrap = artifacts.require('OneSplitViewWrap');
const OneSplit = artifacts.require('OneSplit');
const OneSplitWrap = artifacts.require('OneSplitWrap');
const IMooniswapRegistry = artifacts.require('IMooniswapRegistry');
const IMooniswap = artifacts.require('IMooniswap');

const DISABLE_ALL = new BN('20000000', 16).add(new BN('40000000', 16));
const CURVE_SYNTHETIX = new BN('40000', 16);
const CURVE_COMPOUND = new BN('1000', 16);
const CURVE_ALL = new BN('200000000000', 16);
const KYBER_ALL = new BN('200000000000000', 16);
const MOONISWAP_ALL = new BN('8000000000000000', 16);
const BALANCER_ALL = new BN('1000000000000', 16);

contract('OneSplit', function ([_, addr1]) {
    describe('OneSplit', async function () {
        before(async function () {
            // let mr = await IMooniswapRegistry.at('0xEa579905818Ae70051C057e5E6aF3A5dC85745A4');
            // let addr = await mr.pools('0x0000000000000000000000000000000000000000', '0x6B175474E89094C44Da98b954EedeAC495271d0F');
            // let p = await IMooniswap.at(addr);
            // console.log('p.address', addr);
            // console.log('add', await p.getBalanceForAddition('0x0000000000000000000000000000000000000000'));
            // console.log('rem', await p.getBalanceForRemoval('0x6B175474E89094C44Da98b954EedeAC495271d0F'));

            // exit(1);
            this.subSplitView = await OneSplitView.new();
            this.splitView = await OneSplitViewWrap.new(this.subSplitView.address);

            const subSplit = await OneSplit.new(this.splitView.address);
            this.split = await OneSplitWrap.new(this.splitView.address, subSplit.address);
        });

        // it.only('should work with ETH => CHAI', async function () {
        //     const res = await this.split.swap(
        //         '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
        //         '0x06AF07097C9Eeb7fD685c692751D5C66dB49c215', // CHAI
        //         '100000000000000000000', // 100.0
        //         10,
        //         0, // enable all
        //         { value: '100000000000000000000' }
        //     );

        //     console.log('Swap: 100 ETH');
        //     console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' CHAI');
        //     // console.log('distribution:', res.distribution.map(a => a.toString()));
        //     // console.log('raw:', res.returnAmount.toString());
        // });

        it('should work with Mooniswap ETH => DAI', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
                '1000000000000000000', // 1.0
                10,
                DISABLE_ALL.add(MOONISWAP_ALL), // enable only Mooniswap
            );

            console.log('Swap: 1 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e6 + ' USDC');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.above('390000000');
        });

        it('should work with Balancer ETH => DAI', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
                '1000000000000000000', // 1.0
                10,
                DISABLE_ALL.add(BALANCER_ALL), // enable only Mooniswap
            );

            console.log('Swap: 1 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e6 + ' USDC');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.above('390000000');
        });

        it('should work with ETH => COMP', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
                '0xc00e94Cb662C3520282E6f5717214004A7f26888', // USDC
                '1000000000000000000', // 1.0
                1,
                0,
            );

            console.log('Swap: 1 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e18 + ' COMP');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.above('390000000');
        });

        it('should work with Uniswap USDT => BAL', async function () {
            const res = await this.split.getExpectedReturn(
                '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
                '0xba100000625a3754423978a60c9317c58a424e3D', // BAL
                '100000000', // 1.0
                10,
                DISABLE_ALL.addn(1), // enable only Uniswap V1
            );

            console.log('Swap: 1 USDT');
            console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' BAL');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.equals('0');
        });

        it('should work with DAI => mUSD', async function () {
            const res = await this.split.getExpectedReturn(
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
                '0xe2f2a5C287993345a840Db3B0845fbC70f5935a5', // mUSD
                '2000000', // 2.0
                1,
                DISABLE_ALL.add(web3.utils.toBN('0x20000000000')), // enable only mStable mUSD
            );

            console.log('Swap: 2 USDC');
            console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' mUSD');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.equals('2000000000000000000');
        });

        it('should work with Bancor USDT => BAL', async function () {
            const res = await this.subSplitView.getExpectedReturn(
                '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
                '0xba100000625a3754423978a60c9317c58a424e3D', // BAL
                '100000000', // 1.0
                10,
                DISABLE_ALL.addn(4), // enable only Bancor
            );

            console.log('Swap: 1 USDT');
            console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' BAL');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.equals('0');
        });

        it('should work with Uniswap ETH => DAI', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
                '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI
                '1000000000000000000', // 1.0
                10,
                DISABLE_ALL.addn(1), // enable only Uniswap V1
            );

            console.log('Swap: 1 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' WBTC');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.above('200000000000000000000');
        });

        it('should work with Kyber ETH => DAI', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
                '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI
                '1000000000000000000', // 1.0
                10,
                DISABLE_ALL.add(KYBER_ALL), // enable only Kyber
            );

            console.log('Swap: 1 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' WBTC');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.above('200000000000000000000');
        });

        it.only('should work with Kyber ETH => USDT', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
                '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
                '50000000000000000000', // 50.0
                10,
                DISABLE_ALL.add(KYBER_ALL), // enable only Kyber
            );

            console.log('Swap: 1 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e6 + ' USDT');
            console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.returnAmount).to.be.bignumber.above('200000000000000000000');
        });

        it('should split among BTC Curves', async function () {
            const res = await this.split.getExpectedReturn(
                '0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D', // renBTC
                '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', // WBTC
                '100000000000', // 1000.00
                10,
                DISABLE_ALL.add(CURVE_ALL), // enable only all curves
            );

            console.log('Swap: 100 renBTC');
            console.log('returnAmount:', res.returnAmount.toString() / 1e8 + ' WBTC');
            // console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.distribution.filter(r => r.gt(new BN(0))).length).to.be.equals(2);
        });

        it('should split among USD Curves', async function () {
            const res = await this.split.getExpectedReturn(
                '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
                '1000000000000000000000000', // 1,000,000.00
                4,
                DISABLE_ALL.add(CURVE_COMPOUND).add(CURVE_SYNTHETIX), // enable only all curves
            );

            console.log('Swap: 1,000,000 DAI');
            console.log('returnAmount:', res.returnAmount.toString() / 1e18 + ' USDC');
            console.log('distribution:', res.distribution.map(a => a.toString()));
            // console.log('raw:', res.returnAmount.toString());
            expect(res.distribution.filter(r => r.gt(new BN(0))).length).to.be.above(1);
        });

        it('should work', async function () {
            // const tx = await this.split.getExpectedReturnMock(
            //     '0x0000000000000000000000000000000000000000',
            //     '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359',
            //     web3.utils.toWei('20'),
            //     10
            // );
            const res = await this.split.getExpectedReturn(
                '0x0000000000000000000000000000000000000000', // ETH
                '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359', // DAI
                web3.utils.toWei('20'),
                10,
                4,
            );
            console.log('input: 20 ETH');
            console.log('returnAmount:', res.returnAmount.toString() / 1e18 + ' DAI');
            // console.log('distribution:', res.distribution.map(a => a.toString()));

            console.log('raw:', res.returnAmount.toString());
        });

        it('should return same input (DAI to bDAI)', async function () {
            const inputAmount = '84';

            const res = await this.split.getExpectedReturn(
                '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI
                '0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8', // bDAI
                web3.utils.toWei(inputAmount),
                10,
                0,
            );

            const returnAmount = web3.utils.fromWei(res.returnAmount.toString(), 'ether');

            assert.strictEqual(
                returnAmount,
                inputAmount,
                'Invalid swap ratio',
            );

            console.log(`input: ${inputAmount} DAI`);
            console.log(`returnAmount: ${returnAmount} bDAI`);
            // console.log('distribution:', res.distribution.map(a => a.toString()));

            console.log('raw:', res.returnAmount.toString());
        });

        it('should return same input (bDAI to DAI)', async function () {
            const inputAmount = '84';

            const res = await this.split.getExpectedReturn(
                '0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8', // bDAI
                '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI
                web3.utils.toWei(inputAmount),
                10,
                4,
            );

            const returnAmount = web3.utils.fromWei(res.returnAmount.toString(), 'ether');

            assert.strictEqual(
                returnAmount,
                inputAmount,
                'Invalid swap ratio',
            );

            console.log(`input: ${inputAmount} bDAI`);
            console.log(`returnAmount: ${returnAmount} DAI`);
            // console.log('distribution:', res.distribution.map(a => a.toString()));

            console.log('raw:', res.returnAmount.toString());
        });

        it('should give return from ETH to bDAI', async function () {
            const inputAmount = '20';

            const res = await this.split.getExpectedReturn(
                '0x0000000000000000000000000000000000000000', // ETH
                '0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8', // bDAI
                web3.utils.toWei(inputAmount),
                10,
                4,
            );

            const returnAmount = web3.utils.fromWei(res.returnAmount.toString(), 'ether');

            console.log(`input: ${inputAmount} ETH`);
            console.log(`returnAmount: ${returnAmount} bDAI`);
            // console.log('distributionBdai:', res.distribution.map(a => a.toString()));

            console.log('raw:', res.returnAmount.toString());
        });
    });
});
