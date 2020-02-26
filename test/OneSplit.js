// const { expectRevert } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');
const assert = require('assert');

const OneSplitMock = artifacts.require('OneSplitMock');

contract('OneSplit', function ([_, addr1]) {
    describe('OneSplit', async function () {
        beforeEach('should be ok', async function () {
            this.split = await OneSplitMock.new();
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
            console.log('distribution:', res.distribution.map(a => a.toString()));

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
            console.log('distribution:', res.distribution.map(a => a.toString()));

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
            console.log('distribution:', res.distribution.map(a => a.toString()));

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
            console.log('distributionBdai:', res.distribution.map(a => a.toString()));

            console.log('raw:', res.returnAmount.toString());
        });
    });
});
