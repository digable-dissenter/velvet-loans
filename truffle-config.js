module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 4444,
      network_id: "*"
    },
  },
  compilers: {
    solc: {
      version: "0.5.16",
    }
  }
}