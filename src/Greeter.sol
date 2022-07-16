// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @title Greeter
contract Greeter {
  string public _gm;
  address public owner;

  // CUSTOMS
  error BadGm();
  event GMEverybodyGM();

  constructor(string memory newGm) {
    _gm = newGm;
    owner = msg.sender;
  }

  function gm(string memory myGm) external returns(string memory greeting) {
    if (keccak256(abi.encodePacked((myGm))) != keccak256(abi.encodePacked((greeting = _gm)))) revert BadGm();
    emit GMEverybodyGM();
  }

  function setGm(string memory newGm) external {
    _gm = newGm;
  }
}
