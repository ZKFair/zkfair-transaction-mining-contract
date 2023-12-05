const { ethers, upgrades} = require('hardhat');

const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const pathOutputJson = path.join(__dirname, '../deploy_output.json');
let deployOutput = {};
if (fs.existsSync(pathOutputJson)) {
  deployOutput = require(pathOutputJson);
}
async function main() {
  let deployer = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
  console.log(await deployer.getAddress())
  const rewardDistributionFactory = await ethers.getContractFactory("RewardDistribution", deployer);

  let rewardDistributionContract;
  if (deployOutput.rewardDistributionContract === undefined || deployOutput.rewardDistributionContract === '') {
    rewardDistributionContract = await upgrades.deployProxy(
        rewardDistributionFactory,
        [
          process.env.INITIAL_OWNER,
          process.env.ZKF_TOKEN_ADDRESS,
          process.env.PROPOSAL_AUTHORITY,
          process.env.REVIEW_AUTHORITY,
          process.env.TOTAL_OUTPUT,
        ],
        {
          constructorArgs: [
          ],
          unsafeAllow: ['constructor', 'state-variable-immutable'],
        });
    console.log('tx hash:', rewardDistributionContract.deploymentTransaction().hash);
  } else {
    rewardDistributionContract = rewardDistributionFactory.attach(deployOutput.rewardDistributionContract);
  }

  deployOutput.rewardDistributionContract = rewardDistributionContract.target;
  fs.writeFileSync(pathOutputJson, JSON.stringify(deployOutput, null, 1));
  console.log('#######################\n');
  console.log('RewardDistributionContract deployed to:', rewardDistributionContract.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
