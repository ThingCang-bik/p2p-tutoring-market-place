// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract P2PTutoringMarketplace {

    struct Tutor {
        address payable tutorAddress;
        string name;
        string expertise;
        uint ratePerHour; // in wei
        bool isRegistered;
    }

    struct Session {
        uint id;
        address payable tutor;
        address student;
        uint duration; // in hours
        uint price; // total price in wei
        bool isCompleted;
        bool isPaid;
    }

    struct Rating {
        uint sessionId;
        address rater;
        uint8 rating; // 1 to 5
        string feedback;
    }

    mapping(address => Tutor) public tutors;
    mapping(uint => Session) public sessions;
    mapping(uint => Rating[]) public sessionRatings;

    uint public sessionCount = 0;

    event TutorRegistered(address tutor, string name, string expertise, uint ratePerHour);
    event SessionRequested(uint sessionId, address tutor, address student, uint duration, uint price);
    event SessionCompleted(uint sessionId, address tutor, address student);
    event RatingSubmitted(uint sessionId, address rater, uint8 rating, string feedback);

    modifier onlyRegisteredTutor() {
        require(tutors[msg.sender].isRegistered, "You are not a registered tutor");
        _;
    }

    function registerTutor(string memory name, string memory expertise, uint ratePerHour) public {
        require(!tutors[msg.sender].isRegistered, "Tutor already registered");

        tutors[msg.sender] = Tutor(payable(msg.sender), name, expertise, ratePerHour, true);

        emit TutorRegistered(msg.sender, name, expertise, ratePerHour);
    }

    function requestSession(address payable tutorAddress, uint duration) public payable {
        require(tutors[tutorAddress].isRegistered, "Tutor is not registered");

        uint price = tutors[tutorAddress].ratePerHour * duration;
        require(msg.value == price, "Incorrect payment amount");

        sessionCount++;
        sessions[sessionCount] = Session(sessionCount, tutorAddress, msg.sender, duration, price, false, false);

        emit SessionRequested(sessionCount, tutorAddress, msg.sender, duration, price);
    }

    function completeSession(uint sessionId) public onlyRegisteredTutor {
        Session storage session = sessions[sessionId];
        require(session.tutor == msg.sender, "You are not the tutor for this session");
        require(!session.isCompleted, "Session already completed");

        session.isCompleted = true;
        session.tutor.transfer(session.price);
        session.isPaid = true;

        emit SessionCompleted(sessionId, session.tutor, session.student);
    }

    function submitRating(uint sessionId, uint8 rating, string memory feedback) public {
        Session memory session = sessions[sessionId];
        require(session.student == msg.sender || session.tutor == msg.sender, "You did not participate in this session");
        require(session.isCompleted, "Session is not completed");

        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        sessionRatings[sessionId].push(Rating(sessionId, msg.sender, rating, feedback));

        emit RatingSubmitted(sessionId, msg.sender, rating, feedback);
    }

    function getSessionRatings(uint sessionId) public view returns (Rating[] memory) {
        return sessionRatings[sessionId];
    }
}

