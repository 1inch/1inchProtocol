// const { expectRevert } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');

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
    });
});
