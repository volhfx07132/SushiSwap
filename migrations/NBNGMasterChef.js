const NBNG_ADDRESS = new Map()
NBNG_ADDRESS.set("1", "0x9275e8386a5bdda160c0e621e9a6067b8fd88ea2")
NBNG_ADDRESS.set("4", "0x41c708Fd68C1f1CCF027fABe82996BDE60eDb3A3")

module.exports = async function ({ ethers, deployments, getChainId, getNamedAccounts }) {
  const { deploy } = deployments

  const { deployer, dev } = await getNamedAccounts()

  const chainId = await getChainId()

  if (!NBNG_ADDRESS.has(chainId)) {
    throw Error("No NBNG address")
  }

  const nbng = await NBNG_ADDRESS.get(chainId)
  
  await deploy("NBNGMasterChef", {
    from: deployer,
    args: [nbng, dev, "0"],
    log: true,
    deterministicDeployment: false
  })

  const masterChef = await ethers.getContract("NBNGMasterChef")
  if (await masterChef.owner() !== dev) {
    // Transfer ownership of MasterChef to dev
    console.log("Transfer ownership of NBNGMasterChef to dev")
    await (await masterChef.transferOwnership(dev)).wait()
  }
}

module.exports.tags = ["NBNGMasterChef"]
module.exports.dependencies = ["UniswapV2Factory", "UniswapV2Router02"]
