# Walt's Vault 
ERC721A Smart Contract

### Deployment procedure
#### 1. Install Node.js
To deploy the contracts, you need to have Node.js installed on your machine. If you don’t already have it, you can download it from the official website at https://nodejs.org/en/download/. 
To verify whether Node.js was installed correctly, open the Terminal app (Mac), type the following command and hit the Enter/Return.
```shell
node --version
```
This should print the version of Node.js that you have installed. If you get an error, make sure that Node.js is installed correctly.

#### 2. Install Hardhat
Extract the .zip and open the MerkelCoin folder in Terminal (Right click on the folder > Open in Terminal). 
To install Hardhat, run the following command
```shell
npm install
```
It may take a few minutes to install Hardhat and all its dependencies. 

#### 3. Set your Private Key
Open the `.env` file with any text editor and replace the private key in it with yours. If the file does not exist in the folder, then create a file named `.env` with your text editor and add the private key in the following format
```shell
PRIVATE_KEY = *yourPrivateKey*
```

#### 4. Deploy the contract
You’re now ready to deploy your contract. To do so, simply run the following command
```shell
npm run deploy
```
This will also verify the contracts and print out the contract address.

