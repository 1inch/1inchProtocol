const Migrations = artifacts.require('./Migrations.sol');
// const OneRouter = artifacts.require('./OneRouter.sol');

module.exports = function (deployer) {
    deployer.deploy(Migrations);
    // deployer.deploy(OneRouter);
};
