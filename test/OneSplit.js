// const { expectRevert } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');

const OneSplit = artifacts.require('OneSplit');

contract('OneSplit', function ([_, addr1]) {
    describe('OneSplit', async function () {
        it('should be ok', async function () {
            this.token = await OneSplit.new();
        });
    });
});
