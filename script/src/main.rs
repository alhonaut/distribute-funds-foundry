use ethers::{utils, prelude::*};
use ethers::providers::{Provider, Http};
use std::sync::Arc;
use ethers::utils::parse_ether;
use std::convert::TryFrom;

// ABI of the contract
abigen!(
    SendERC,
    r#"[
        function distributeWithPercentages(address[], uint256[], address)
        function distributeWithAmounts(address[], uint256[], address)
        function collectWithPercentage(address[], uint256[], address, address)
        function collectWithAmount(address[], uint256[], address, address)
    ]"#
);


type Client = SignerMiddleware<Provider<Http>, Wallet<k256::ecdsa::SigningKey>>;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let alchemy_rpc_url: &str = "https://eth-sepolia.g.alchemy.com/v2/{API_KEY}";
    let contract_address: &str = "Contract Address on Sepolia";
    let private_key = "PRIVATE_KEY_FROM_ENV";

    let provider = Provider::<Http>::try_from(alchemy_rpc_url)?;
    let wallet: LocalWallet = private_key.parse::<LocalWallet>()?
    .with_chain_id(Chain::Sepolia);

    let signer = SignerMiddleware::new(provider.clone(), wallet.clone());
    let client = Arc::new(signer);

    let address: Address = contract_address.parse()?;
    let contract = SendERC::new(address, client.clone());

    let addresses: Vec<Address> = vec!["0x00001...".parse()?, "0x00002...".parse()?];
    let percentages: Vec<U256> = vec![U256::from(50), U256::from(50)]; // split 50% between addresses
    let token_address: Address = "0x0000000000000000000000000000000000000000".parse()?; // address(0) = distribute ETH

    let tx = contract
        .distribute_with_percentages(addresses.clone(), percentages, token_address)
        .send()
        .await?.await?;

    println!("Transaction Hash: {:?}", serde_json::to_string(&tx)?);

    Ok(())
}
