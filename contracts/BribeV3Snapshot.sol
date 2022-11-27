// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface erc20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
}

contract BribeV3Snapshot is Ownable {
    struct optionBribe{
        uint option;
        address token;
        uint amount;
    }

    uint constant WEEK = 86400 * 7;
    uint constant PRECISION = 10**18;
    uint8 public feePercentage;
    address public feeAddress;
    address public distributionAddress;

    constructor(uint8 _feePercentage, address _feeAddress, address _distributionAddress){
        set_fee_percentage(_feePercentage);
        set_fee_address(_feeAddress);
        set_distribution_address(_distributionAddress);
    }

    //store mapping of bribed proposals, include a mapping for each option in there so if the proposal array is empty the proposal is not bribed.
    mapping(string => optionBribe[]) public optionBribes;

    mapping(address => bool) public isBlacklisted;

    event Bribe(uint time, address indexed briber, string proposal, uint option, address reward_token, uint amount);

    function rewards_per_proposal(string calldata proposal) external view returns (optionBribe[] memory) {
        return optionBribes[proposal];
    }

    function add_reward_amount(string memory proposal, uint option, address reward_token, uint amount) external returns (bool) {
        uint fee = calculate_fee(amount);
        amount -= fee;
        _safeTransferFrom(reward_token, msg.sender, feeAddress, fee);
        _safeTransferFrom(reward_token, msg.sender, distributionAddress, amount);


        optionBribes[proposal].push(optionBribe(option, reward_token, amount));

        emit Bribe(block.timestamp, msg.sender, proposal, option, reward_token, amount);
        return true;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function set_fee_percentage(uint8 _feePercentage) public onlyOwner {
        require(_feePercentage <= 15, 'Fee too high');
        feePercentage = _feePercentage;
    }

    function set_fee_address(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function set_distribution_address(address _distributionAddress) public onlyOwner {
        distributionAddress = _distributionAddress;
    }

    function calculate_fee(uint amount) public view returns (uint) {
        return amount * feePercentage / 100;
    }

    function blackList(address user) public onlyOwner {
        require(!isBlacklisted[user], "user already blacklisted");
        isBlacklisted[user] = true;
    }

    function removeFromBlacklist(address user) public onlyOwner {
        require(isBlacklisted[user], "user already whitelisted");
        isBlacklisted[user] = false;
    }

}
