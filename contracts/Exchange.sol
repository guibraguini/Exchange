//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";

interface token {
    function balanceOf (address) external view returns (uint256);
}

contract Exchange {
    address owner;
    mapping(address => bool) tokenCheck;
    mapping(address => mapping (address => uint256)) public Liquidit;
    address [] tokens;
    using SafeERC20 for IERC20;

    constructor (address _firstToken) {
        owner = msg.sender;
        
        tokens.push(_firstToken);
        tokenCheck[_firstToken] = true;
    }

    function addToken (address _newToken) public returns (bool sucess) {
        require(tokenCheck[_newToken] == false, "Token Already Registered");
        tokenCheck[_newToken] = true;
        tokens.push(_newToken);
        return true;
    }

    function addLiquidit (address _token, uint256 _value) public returns (bool sucess) {
        require(msg.sender == owner, "Not the Owner");
        recive(_value, _token);
        Liquidit[msg.sender][_token] += _value;
        return true;
    }

    function removeLiquidit (address _token, uint256 _value) public returns (bool sucess) {
        require(msg.sender == owner, "Not the Owner");
        require(Liquidit[msg.sender][_token] >= _value, "Not Enought Tokens");
        Liquidit[msg.sender][_token] -= _value;
        pay(_value, _token);
        return true;
    }

    function recive (uint256 _total, address _tokenAddress) public returns (bool sucess) {
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _total);
        return true;
    }

    function pay (uint256 _total, address _tokenAddress) internal returns (bool sucess) {
        require(token(_tokenAddress).balanceOf(address(this)) - _total >= 0, "Not Enought Tokens on Exchange");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _total);
        return true;
    }

    function change (uint256 _firstToken, uint256 _secondToken, uint256 _value) public returns (bool sucess) {
        address _secondTokenAddress = tokens[_secondToken];
        require(token(_secondTokenAddress).balanceOf(address(this)) >= _value, "Not Enought Tokens on Exchange");
        address _firstTokenAddress = tokens[_firstToken];
        uint256 _total = (token(_firstTokenAddress).balanceOf(address(this)) * _value) / token(_secondTokenAddress).balanceOf(address(this));
        require(recive(_total, _firstTokenAddress) == true, "Token not Recived");
        pay(_value, _secondTokenAddress);
        return true;
    }

    function transferTokens (uint _amount, uint256 _firstToken) public returns (bool) {
        address _tokenAddress = tokens[_firstToken];
        require(token(_tokenAddress).balanceOf(address(this)) >= _amount, "Not Enought Tokens on the Exchange");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
        return true;
    }

    function buyTokens (uint256 _firstToken) payable public {
        address _tokenAddress = tokens[_firstToken];
        uint amount = msg.value * 10;
        require(token(_tokenAddress).balanceOf(address(this)) >= amount, "Not Enought Tokens on the Exchange");
        IERC20(_tokenAddress).safeTransfer(msg.sender, amount);
    }

    function sellTokens (uint _amount, uint256 _firstToken) public {
        address _tokenAddress = tokens[_firstToken];
        require(token(_tokenAddress).balanceOf(msg.sender) >= _amount, "Seller Dosen't Had Enought Tokens");
        uint amount = _amount / 10;
        require(address(this).balance >= amount, "Not Enought Ether");
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this) ,_amount);
        payable(msg.sender).transfer(amount);
    }

    function getBallance (uint256 _firstToken) public view returns (uint256) {
        address _tokenAddress = tokens[_firstToken];
         return token(_tokenAddress).balanceOf(address(this));
    }

}