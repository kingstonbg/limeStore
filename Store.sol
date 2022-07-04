// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Ownable {
    address public administrator;
    
    modifier onlyAdmin() {
        require(administrator == msg.sender, "Not invoked by the administrator.");
        _;
    }
    
    constructor() {
        administrator = msg.sender;
    }
}

contract Store is Ownable {

    uint productsCount;

    struct Product {
        string name;
        uint quantity;
        uint id;
    }

    struct Purchase {
        uint id;
        uint quantity;
        uint blockNumber;
    }

    Product[] public products;

    mapping(uint => Product) productById;
    mapping(string => uint) productIdByName;
    mapping(string => bool) productExists;
    mapping(uint => address[]) buyers;
    mapping(uint => mapping(address => bool)) hasBought;
    mapping(uint => mapping(address => Purchase)) public purchases;

    function returnProduct(uint id) public {
        require(block.number - purchases[id][msg.sender].blockNumber < 100 , "Cannot return product after trial period is over.");
        
        increaseProductQuantity(id, purchases[id][msg.sender].quantity);
    }

    function addProduct(string memory  name, uint quantity) public onlyAdmin {
        if(productExists[name] == false) {
            productsCount++;
            Product memory product = Product(name, quantity, productsCount);
            products.push(product);
            productById[productsCount] = product;
            productExists[name] = true;
            productIdByName[name] = productsCount;
        }
        else {
            increaseProductQuantity(productIdByName[name], quantity);
        }
    }

    function getProducts() public view returns (Product[] memory) {
      Product[] memory id = new Product[](productsCount);
      for (uint i = 0; i < productsCount; i++) {
          Product storage product = products[i];
          id[i] = product;
      }
      return id;
    }

    function buyProduct(uint id, uint quantity) public {
        require(hasBought[id][msg.sender] == false, "Cannot buy the same product more than once.");
        require(productById[id].quantity >= quantity, "Cannot buy more than available.");


        reduceProductQuantity(id, quantity);
        buyers[id].push(msg.sender);
        hasBought[id][msg.sender] = true;
        purchases[id][msg.sender] = Purchase(id, quantity, block.number);
    }

    function reduceProductQuantity(uint id, uint quantity) private {
        for (uint i = 0; i < products.length; i++) {
            if(products[i].id == id) {
                products[i].quantity -= quantity;
            }
        }
        productById[id].quantity -= quantity;
    }

    function increaseProductQuantity(uint id, uint quantity) private {
        for (uint i = 0; i < products.length; i++) {
            if(products[i].id == id) {
                products[i].quantity += quantity;
            }
        }
        productById[id].quantity += quantity;
    }

    function viewBuyersForProduct(uint id) public view returns (address[] memory) {
        return buyers[id];
    }

}
