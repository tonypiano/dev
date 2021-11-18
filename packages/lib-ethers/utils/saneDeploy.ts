import { getContractFactory } from "@nomiclabs/hardhat-ethers/types";

async function _deployContract(deployer, getContractFactory, contractName, args) {
    console.log(`Deploying ${contractName}`);
    const factory = await getContractFactory(contractName, deployer);
    const contract = await factory.deploy(...args);

    console.log(`Waiting for transaction ${contract.deployTransaction.hash} ...`);
    const receipt = await contract.deployTransaction.wait();
    console.log({
        contractAddress: contract.address,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed.toNumber()
    });
    return [contract.address, receipt.blockNumber];
}

async function deployContracts(deployer, getContractFactory, overrides) {
  /// this just deploys the contracts and returns an object of their addresses
  const alwaysContracts = [
    "ActivePool",
    "BorrowerOperations",
    "TroveManager",
    "CollSurplusPool",
    "CommunityIssuance",
    "DefaultPool",
    "HintHelpers",
    "LockupContractFactory",
    "LQTYStaking",
    "SortedTroves",
    "StabilityPool",
    "GasPool",
    "Unipool",
  ];

  const testnetContracts = [
      "PriceFeedTestnet"
  ];

  const mainnetContracts = [
    "PriceFeed"
  ];

  let firstBlock;
  const addresses = {};

  for (const contractName in alwaysContracts.concat(testnetContracts)) {
      const [address, blockNumber] = await _deployContract(deployer, getContractFactory, contractName, {...overrides});
      if (typeof firstBlock === "undefined") {
          firstBlock = blockNumber;
      }
      addresses[contractName] = address;
  }

let [lusdTokenAddress, _] = await _deployContract(
    deployer,
    getContractFactory,
    "LUSDToken",
    addresses.troveManager,
    addresses.stabilityPool,
    addresses.borrowerOperations,
    { ...overrides }
);
addresses["LUSDToken"] = lusdTokenAddress;

let [lqtyTokenAddress, _] = await _deployContract(
        deployer,
        getContractFactory,
        "LQTYToken",
        addresses.CommunityIssuance,
        addresses.LQTYStaking,
        addresses.LockupContractFactory,
        Wallet.createRandom().address, // _bountyAddress (TODO: parameterize this)
        addresses.Unipool, // _lpRewardsAddress
        Wallet.createRandom().address, // _multisigAddress (TODO: parameterize this)
        { ...overrides }
);
addresses["LQTYToken"] = lqtyTokenAddress;

let [multiTroveGetterAddress, _] = await _deployContract(
    deployer,
    getContractFactory,
    "MultiTroveGetter",
    addresses.TroveManager,
    addresses.SortedTroves,
    { ...overrides }
);
addresses["MultiTroveGetter"] = multiTroveGetterAddress;

  ];
  return [addresses, startBlock];
}

async function configureContracts(deployedAddresses) {
    ///  this configures all the contracts
}

export async function deployAndSetupContracts(
    deployer: Signer,
    getContractFactory: (name: string, signer: Signer) => Promise<ContractFactory>,
    _priceFeedIsTestnet = true,
    _isDev = true,
    wethAddress?: string,
    overrides?: Overrides
) {
    const [addresses, startBlock ] = await deployContracts(deployer, getContractFactory, overrides);
    await configureContracts(addresses);

    return {
    chainId: await deployer.getChainId(),
    version: "unknown",
    deploymentDate: new Date().getTime(),
    bootstrapPeriod: 0,
    totalStabilityPoolLQTYReward: "0",
    liquidityMiningLQTYRewardRate: "0",
    _priceFeedIsTestnet,
    _uniTokenIsMock: !wethAddress,
    _collateralTokenIsMock: !wethAddress,
    _isDev,
    }
}
