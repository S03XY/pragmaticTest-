// SPDX-License-Identifier:None
pragma solidity 0.8.7;

contract MultiPartyWallet {
    address private _adminstrator;
    address[] private _ownerList;
    uint256 public approvalPercentage;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    Transaction[] public transacion;
    mapping(uint256 => mapping(address => bool)) private approvedTransactions;
    mapping(address => bool) public isOwner;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    modifier OnlyAdmin() {
        require(msg.sender == _adminstrator, "Not a admin");
        _;
    }

    constructor(address admin) {
        _adminstrator = admin;
    }

    function addOwner(address newOwner) external OnlyAdmin {
        require(newOwner != address(0), "invalid owner");
        address[] memory _ownerListCopy = _ownerList;
        uint256 length = _ownerListCopy.length;
        int256 index = -1;
        for (uint256 i = 0; i < length; i++) {
            if (_ownerListCopy[i] == newOwner) {
                index = int256(i);
            }
        }
        require(index == -1, "owner already exits");
        _ownerList.push(newOwner);
        isOwner[newOwner] = true;
        emit OwnerAdded(newOwner);
    }

    function removeOwner(address ownerToRemove) external OnlyAdmin {
        require(ownerToRemove != address(0), "invalid owner");
        address[] memory _ownerListCopy = _ownerList;
        uint256 length = _ownerListCopy.length;
        int256 index = -1;

        for (uint256 i = 0; i < length; i++) {
            if (_ownerListCopy[i] == ownerToRemove) {
                index = int256(i);
            }
        }

        require(index != -1, "owner does not exits");
        delete _ownerList[uint256(index)];
        isOwner[ownerToRemove] = false;
        emit OwnerRemoved(ownerToRemove);
    }

    function getOwners() external view returns (address[] memory) {
        return _ownerList;
    }

    function setApprovalPercentage(uint256 approvalper) external OnlyAdmin {
        require(
            approvalper <= 100 && approvalper > 0,
            "approval percentage must be greater than 0 and less than or equal to 100"
        );
        approvalPercentage = approvalper;
    }

    function executeProposal(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external {
        require(isOwner[msg.sender], "not owner");
        transacion.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
    }

    function approveTransaction(uint256 tranactionIndex) external {
        require(isOwner[msg.sender], "not owner");
        require(
            tranactionIndex < transacion.length,
            "transaction doesnt exits"
        );
        require(
            transacion[tranactionIndex].executed == false,
            "already executed"
        );
        Transaction storage getTransaction = transacion[tranactionIndex];
        bool isapproved = approvedTransactions[tranactionIndex][msg.sender];
        require(isapproved != true, "already approved");

        getTransaction.numConfirmations += 1;
        approvedTransactions[tranactionIndex][msg.sender] = true;
    }

    function executeTransaction(uint256 transactionIndex) external {
        require(isOwner[msg.sender], "not owner");
        require(
            transactionIndex < transacion.length,
            "transaction doesnt exits"
        );
        require(
            transacion[transactionIndex].executed == false,
            "already executed"
        );
        Transaction storage gettransaction = transacion[transactionIndex];
        uint256 confirmed = gettransaction.numConfirmations;
        uint256 total = _ownerList.length;
        uint256 percentage = (confirmed * 100) / total;

        require(percentage > approvalPercentage, "not enough approvals");
        gettransaction.executed = true;

        (bool success, ) = gettransaction.to.call{value: gettransaction.value}(
            gettransaction.data
        );
        require(success, "tx failed");
    }
}

contract Test {
    function testfunction() external pure returns (bool) {
        return true;
    }

    function getdata() external pure returns (bytes memory) {
        return abi.encodeWithSignature("testfunction");
    }
}

//  steps to execute

// Admin will execute addOwner
// Admin will execute setApprovalPercentage
// owner will execute executeProposal
// owner will execute approveTransaction
// owner will execute executeTransaction
