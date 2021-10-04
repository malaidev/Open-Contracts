const path = require("path");
const fs = require("fs");
const solc = require("solc");

const tokenListPath = path.resolve(__dirname, "contracts", "TokenList.sol");
const source = fs.readFileSync(tokenListPath, "utf8");

module.exports = solc.compile(source, 1).contracts[":TokenList"];
