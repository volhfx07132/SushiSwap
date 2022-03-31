const NBNG_ADDRESS = new Map()
NBNG_ADDRESS.set("1", "0x9275e8386a5bdda160c0e621e9a6067b8fd88ea2")
NBNG_ADDRESS.set("4", "0x41c708Fd68C1f1CCF027fABe82996BDE60eDb3A3")

module.exports = async function ({ getNamedAccounts, getChainId, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const chainId = await getChainId()

  if (!NBNG_ADDRESS.has(chainId)) {
    throw Error("No NBNG address")
  }

  const nbng = await NBNG_ADDRESS.get(chainId)

  await deploy("NBNGBar", {
    from: deployer,
    args: [nbng],
    log: true,
    deterministicDeployment: false
  })
}

module.exports.tags = ["NBNGBar"]
module.exports.dependencies = ["UniswapV2Factory", "UniswapV2Router02"]
