async function main() {

    const [deployer] = await ethers.getSigners();
  
    console.log(
      "Deploying contracts with the account:",
      deployer.address
    );
    
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const AMZEToken = await ethers.getContractFactory("AMZEToken");
    const _amzeToken = await AMZEToken.deploy();
  
    console.log("Token address:", _amzeToken.address);
    
    const ownerBalance = (await _amzeToken.balanceOf(deployer.address)).toString();
    console.log("Token Balance:", ownerBalance);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });