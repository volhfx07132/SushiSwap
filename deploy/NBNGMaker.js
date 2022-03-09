const { WETH } = require("@sushiswap/sdk")

const NBNG_ADDRESS = new Map()
NBNG_ADDRESS.set("1", "0x9275e8386a5bdda160c0e621e9a6067b8fd88ea2")
NBNG_ADDRESS.set("4", "0x41c708Fd68C1f1CCF027fABe82996BDE60eDb3A3")

module.exports = async function ({ ethers: { getNamedSigner }, getNamedAccounts, getChainId, deployments }) {
  const { deploy } = deployments

  const { deployer, dev } = await getNamedAccounts()

  const chainId = await getChainId()

  if (!NBNG_ADDRESS.has(chainId)) {
    throw Error("No NBNG address")
  }

  const factory = await ethers.getContract("UniswapV2Factory")
  const bar = await ethers.getContract("NBNGBar")
  const nbng = await NBNG_ADDRESS.get(chainId)
  
  let wethAddress;
  
  if (chainId === '31337') {
    wethAddress = (await deployments.get("WETH9Mock")).address
  } else if (chainId in WETH) {
    wethAddress = WETH[chainId].address
  } else {
    throw Error("No WETH!")
  }

  await deploy("NBNGMaker", {
    from: deployer,
    args: [factory.address, bar.address, nbng, wethAddress],
    log: true,
    deterministicDeployment: false
  })

  const maker = await ethers.getContract("NBNGMaker")
  if (await maker.owner() !== dev) {
    console.log("Setting maker owner")
    await (await maker.transferOwnership(dev, true, false)).wait()
  }
}

module.exports.tags = ["NBNGMaker"]
module.exports.dependencies = ["UniswapV2Factory", "UniswapV2Router02", "NBNGBar"]