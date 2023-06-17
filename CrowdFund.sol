// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract CrowdFundManager {

    //Status of a campaign that has been launched is tracked through an enum
    enum Status {
        Ongoing,
        Cancelled,
        Success,
        Failed
    }

    //The Campaign struct tracks the attributes of a campaign
    struct Campaign {
        address owner; //owner is the benefactor/organisation who is raising money
        uint endTime; //time that the campaign stops accepting donations/contributions
        uint32 targetAmt;
        uint32 currAmt;
        Status status;
    }

    //This mapping maps the name of the campaign(string) to the Campaign struct.
    mapping (string => Campaign) public campaigns;
    //Another mapping to track the funders of a certain campaign.
    mapping (string => mapping(address => uint32)) public fundersToAmt;
    //tracks whether a campaign exists.
    mapping (string => bool) public isValidCampaign;

    //events to notify the front-end about the outcome of the campaigns.
    event Cancel(string indexed nameOfCancelledCampaign);
    event Fail(string indexed nameOfFailedCampaign);
    event AbleToDelete(string indexed deletableCampaign);

    function launch(string memory name, uint duration, uint32 targetAmt) public {
        require(!isValidCampaign[name]);  //check to make sure name of the campaign being launched is unique.
        uint endTime = block.timestamp + duration;
        Campaign memory myCampaign = Campaign(msg.sender, endTime, targetAmt, 0, Status(0));
        campaigns[name] = myCampaign;
        isValidCampaign[name] = true;
    }

    function fund(string memory name) external payable {
        require(isValidCampaign[name], "Campaign does not exist!");
        require(campaigns[name].status == Status(0), "Campaign is not ongoing!"); //checks that users contribute to an ongoing campaign!.
        Campaign storage mycampaign = campaigns[name];
        mycampaign.currAmt += uint32(msg.value);
        fundersToAmt[name][msg.sender] += uint32(msg.value);
    }

    function withdraw(string memory name) external {
        Campaign storage myCampaign = campaigns[name];
        //checks that current time is greater than the endTime of campaign
        require(block.timestamp > myCampaign.endTime, "Campaign is still ongoing!");
        //targetamt acheived
        if(myCampaign.currAmt >= myCampaign.targetAmt){
            uint funds = myCampaign.currAmt;
            myCampaign.currAmt = 0;
            //pays the owner/benefactor of campaign
            payable(myCampaign.owner).transfer(funds);
            myCampaign.status = Status(2);
            //let people know that this campaign can now be deleted
            emit AbleToDelete(name);
        }else{
            myCampaign.status = Status(3);
            //emit a campaign failed event
            emit Fail(name);
        }
    }

    function refund(string memory name) external {
        Campaign storage myCampaign = campaigns[name];
        // contributors can only withdraw funds if the campaign has been cancelled or failed !
        require(myCampaign.status == Status(1) || myCampaign.status == Status(3), "Not able to refund.");
        require(fundersToAmt[name][msg.sender] > 0, "You did not contribute to this campaign!");
        uint32 amt = fundersToAmt[name][msg.sender];
        fundersToAmt[name][msg.sender] = 0;
        myCampaign.currAmt -= amt;
        payable(msg.sender).transfer(amt);
        if(myCampaign.currAmt == 0){
            //let people know that this campaign can now be deleted
            emit AbleToDelete(name);
        }
    }

    function cancelCampaign(string memory name) external {
        Campaign storage myCampaign = campaigns[name];
        require(myCampaign.owner == msg.sender, "Not owner");
        require(block.timestamp < myCampaign.endTime);
        myCampaign.status = Status(1);
        //emit an campaign cancelled event
        emit Cancel(name);
    }

    function deleteCampaign(string memory name) external {
        require(isValidCampaign[name] && campaigns[name].status != Status(0), "Invalid campaign or cannot delete ongoing campaign!");
        Campaign memory myCampaign = campaigns[name];
        require(myCampaign.currAmt == 0, "refund to contributors not complete/funds not withdrawn!");
        delete campaigns[name];
        isValidCampaign[name] = false;
    }

    //send ether back to the sender if msg.data is not empty using fallback
    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    //send ether back to the sender if msg.data is empty using receive
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
