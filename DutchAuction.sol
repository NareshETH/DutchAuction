// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {

  function transferFrom(address _from,address _to,uint256 _nftId) external ;
    
}

contract DutchAuction{
 
  //Duration of the Auction
  uint32 private constant DURATION = 1 days;

  IERC721 nft;
  uint256 nftId;

  address payable  public  seller;

  uint32 public startAt;
  uint32 public endAt;
  uint256 public startingPrice;
  uint256 public discountRate;


  //assigning state variables
  constructor(
      uint256 _startingPrice,
      uint256 _discountRate,
      uint256 _nftId,
      address _nft){

      startAt = block.timestamp;
      endAt = block.timestamp + DURATION;
      startingPrice = _startingPrice;
      discountRate = _discountRate;
      nftId = _nftId;
      nft = IERC721(_nft);
      seller = payable (msg.sender);

      require(_startingPrice >= _discountRate * DURATION,"Not Enough Starting Price");

       }

    //returns the current price decreases every seconds
    function getPrice() public view returns (uint256){

        uint256 time = block.timestamp - startAt;
        uint256 discount = discountRate * time;
        return startingPrice - discount;
    }


   error AuctionEnded();
   error NotEnough_ETH();
   error Call_Failed();


   //allows to buy the nft 
   function buy() external payable  {

       if(block.timestamp > endAt){
           revert AuctionEnded();
       }

       uint256 price = getPrice();
       if(msg.value < price){
           revert NotEnough_ETH();
       }

       nft.transferFrom(seller, msg.sender, nftId);
       uint256 refund = msg.value - price;
      
      //refunded the execess amount to the buyer
       if(refund > 0){

         (bool success,) = payable (msg.sender).call{value:refund}("");

       if(!success){

         revert Call_Failed();

         }
       }
       
       //selfdestruct the contract to end the Auction
       selfdestruct(seller);

   }


}