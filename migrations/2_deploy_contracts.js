var Betting = artifacts.require("./NBAGame.sol");
module.exports = function(deployer) {
    deployer.deploy(Betting);
};