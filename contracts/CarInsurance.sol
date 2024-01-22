// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CarInsurance {
    
    uint256 insuranceTypesCount;
 
    // Struct to represent details of each insurance type
    struct InsuranceType {
        string name;
        uint256 charges;                                                        
        string[] privileges;
    }

    struct TransferStruct {
        address sender;  //msg.sender    
        uint amount;   //msg.value      
        uint256 timestamp;  //block.timestamp
    }

    TransferStruct[] transactions;

    // Mapping to store insurance types
    mapping(uint256 => InsuranceType) public insuranceTypes;

    // Mapping to track user's selected insurance type
    mapping(address => uint256) public clientInsuranceSelection;

    // Modifier to ensure only the owner can perform certain actions
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Address of the contract owner
    address public owner;

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Function to add a new insurance type
    function addInsuranceType(uint256 typeId, string memory name, uint256 charges, string[] memory privileges) external {
        insuranceTypes[typeId] = InsuranceType(name, charges, privileges);
        insuranceTypesCount++;
    }

    // Function to get all insurance types
    function getAllInsuranceTypes() external view returns (InsuranceType[] memory) {
        InsuranceType[] memory allInsuranceTypes= new InsuranceType[](insuranceTypesCount);
        
        for (uint256 i = 0; i < insuranceTypesCount; i++) {
            allInsuranceTypes[i] = insuranceTypes[i];
        }
        return allInsuranceTypes;
    }

    // Function to allow users to select an insurance type
    function selectInsuranceType(uint256 typeId) external {
        require(insuranceTypes[typeId].charges > 0, "Invalid insurance type");
        clientInsuranceSelection[msg.sender] = typeId;
    }

    // Function to query coverage details for a specific insurance type
    function getCoverageDetails(uint256 typeId) external view returns (string memory name, uint256 charges, string[] memory privileges) {
        InsuranceType memory insurance = insuranceTypes[typeId];
        return (insurance.name, insurance.charges, insurance.privileges);
    }

    // Mapping to track insurance activation time
    mapping(address => uint256) public insuranceActivationTime;

    // Event to log insurance purchase
    event InsurancePurchased(address indexed client, uint256 insuranceType, uint256 timestamp);

    // Function to purchase insurance
    function purchaseInsurance() external payable {
        uint256 typeId = clientInsuranceSelection[msg.sender];
        require(typeId > 0, "Insurance type not selected");

        InsuranceType memory selectedInsurance = insuranceTypes[typeId];
        require(msg.value == selectedInsurance.charges, "Insufficient charges amount");

        emit InsurancePurchased(msg.sender, typeId, block.timestamp);
        
        insuranceActivationTime[msg.sender] = block.timestamp;  //activate insurance and set activation time
        
        transactions.push(TransferStruct(msg.sender, msg.value, block.timestamp));
    }

    //get all client's insurances
    function getAllClientInsurances(address client) public view returns (uint256[] memory, uint256[] memory, string[] memory, uint256[] memory) {
    uint256[] memory insuranceTypesList = new uint256[](insuranceTypesCount);
    uint256[] memory activationTimes = new uint256[](insuranceTypesCount);
    string[] memory insuranceNames = new string[](insuranceTypesCount);
    uint256[] memory insuranceCharges = new uint256[](insuranceTypesCount);
    uint256 count = 0;
    for (uint256 i = 1; i <= insuranceTypesCount; i++) {
        if (clientInsuranceSelection[client] == i && insuranceActivationTime[client] > 0) {
            insuranceTypesList[count] = i;
            activationTimes[count] = insuranceActivationTime[client];
            insuranceNames[count] = insuranceTypes[i].name;
            insuranceCharges[count] = insuranceTypes[i].charges;
            count++;
        }
    }
    // Resize the arrays to the actual count
    assembly {
        mstore(insuranceTypesList, count)
        mstore(activationTimes, count)
        mstore(insuranceNames, count)
        mstore(insuranceCharges, count)
    }

    return (insuranceTypesList, activationTimes, insuranceNames, insuranceCharges);
    }

    // Function to perform monthly transactions for active insurances
    function monthlyTransaction() external payable{
        uint256 typeId = clientInsuranceSelection[msg.sender];
        require(typeId > 0, "Insurance type not selected");
        require(insuranceActivationTime[msg.sender] > 0, "Insurance not activated");

        InsuranceType memory selectedInsurance = insuranceTypes[typeId];
        require(isInsuranceActive(msg.sender), "Insurance not active");

        // Perform the monthly transaction (you can customize this part)
        uint256 monthlyCharge = selectedInsurance.charges;
        require(msg.value == monthlyCharge, "Insufficient charges amount");

        // Emit an event or perform other actions for the monthly transaction
        emit MonthlyTransaction(msg.sender, typeId, block.timestamp);

        transactions.push(TransferStruct(msg.sender, msg.value, block.timestamp));
    }

    // Event to log monthly transactions
    event MonthlyTransaction(address indexed client, uint256 insuranceType, uint256 timestamp);

    // Internal function to check if insurance is active
    function isInsuranceActive(address client) internal view returns (bool) {
        uint256 activationTime = insuranceActivationTime[client];
        return block.timestamp < activationTime + 12 * 30 days; 
    }

    // Event to log transactions where the owner sends an amount to a client
    event AmountSentToClient(address indexed owner, address indexed client, uint256 amount, uint256 timestamp);

    // Function to allow the owner to send an amount to a client
    function sendAmountToClient(address payable client, uint256 amount) external onlyOwner {
        require(client != address(0), "Invalid client address");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer the specified amount to the client
        payable(client).transfer(amount);
        
        // Emit an event to log the transaction
        emit AmountSentToClient(msg.sender, client, amount, block.timestamp);

        transactions.push(TransferStruct(msg.sender, amount, block.timestamp));
    }

    // get clinet's transaction: monthlyTransaction  and purchasing the Insurances
    mapping(address => TransferStruct[]) public clientTransactions;
    function getAllClientTransactions(address client) public view returns (TransferStruct[] memory) {
        return clientTransactions[client];
    }

    // get all client's receives transactions
    function getAllClientReceive(address client) public view returns (TransferStruct[] memory) {
        TransferStruct[] memory clientReceiveTransactions;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].sender != client) {
                clientReceiveTransactions[i] = transactions[i];
            }
        }
        return clientReceiveTransactions;
    }

}
