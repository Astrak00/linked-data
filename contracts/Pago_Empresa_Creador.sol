// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract ArtistPayment {
    address public company;
    
    struct Payment {
        address artist;
        uint256 amount;
        uint256 timestamp;
    }
    
    struct UserListening {
        address user;
        uint256 listenPercentage;
    }
    
    mapping(address => uint256) public artistEarnings;
    Payment[] public paymentHistory;
    
    event PaymentProcessed(address indexed artist, uint256 amount);
    
    modifier onlyCompany() {
        require(msg.sender == company, "Only company can execute this");
        _;
    }
    
    constructor() {
        company = msg.sender;
    }
    
    
    // Generar lista de usuarios con sus porcentajes de escucha
    function _getUserListenings(address artist) internal view returns (UserListening[] memory) {
        uint256 userCount = 10;
        UserListening[] memory users = new UserListening[](userCount);
        
        for (uint256 i = 0; i < userCount; i++) {
            address pseudoUser = address(uint160(uint256(keccak256(abi.encodePacked(artist, i, block.number)))));
            uint256 totalListens = uint256(keccak256(abi.encodePacked(artist, i, "total"))) % 1000 + 100;
            uint256 artistListens = uint256(keccak256(abi.encodePacked(artist, i, "artist"))) % (totalListens + 1);
            
            uint256 percentage = (artistListens * 100) / totalListens;
            
            users[i] = UserListening({
                user: pseudoUser,
                listenPercentage: percentage
            });
        }
        
        return users;
    }
    
    // Obtener tipo de suscripción de cada usuario (1, 2, 3)
    function _getUserSubscriptionPrice(address user, uint256 nonce) internal view returns (uint256) {
        uint256 subscriptionType = (uint256(keccak256(abi.encodePacked(user, nonce, block.number))) % 3) + 1;
        
        if (subscriptionType == 1) {
            return 7000000000000000; // 0.007 ETH
        } else if (subscriptionType == 2) {
            return 10000000000000000; // 0.01 ETH
        } else {
            return 15000000000000000; // 0.015 ETH
        }
    }
    
    // Calcular pago basado en usuarios, sus porcentajes y suscripciones
    function _calculatePayment(address artist) internal view returns (uint256) {
        UserListening[] memory users = _getUserListenings(artist);
        
        uint256 totalRevenue = 0;
        
        // Para cada usuario, calcular el pago
        for (uint256 i = 0; i < users.length; i++) {
            uint256 subscriptionPrice = _getUserSubscriptionPrice(users[i].user, i);
            
            uint256 userRevenue = users[i].listenPercentage * subscriptionPrice / 100;
            totalRevenue += userRevenue;
        }
        
        // El artista recibe el 70% del total
        uint256 artistPayment = (totalRevenue * 70) / 100;
        
        return artistPayment;
    }
    
    // Comprobar artista. Funcionamiento por decidir
    function verifyArtist(address artist) public pure returns (bool) {
        require(artist != address(0), "Invalid artist address");
        return true;
    }
    
    // Realizar pago
    function performPayment(address artist) public onlyCompany {
        require(verifyArtist(artist), "Artist does not exist");
        
        uint256 amount = _calculatePayment(artist);
        require(amount > 0, "Calculated payment must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        artistEarnings[artist] += amount;
        
        (bool success, ) = payable(artist).call{ value: amount }("");
        require(success, "Payment transfer failed");
        
        paymentHistory.push(Payment({
            artist: artist,
            amount: amount,
            timestamp: block.timestamp
        }));
        
        emit PaymentProcessed(artist, amount);
    }
    
    // Recibir fondos
    receive() external payable {}
}