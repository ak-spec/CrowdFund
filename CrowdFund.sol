// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract CrowdFundManager {

    enum Status {
        Ongoing,
        Cancelled,
        Success,
        Failed
    }

    struct Campaign {
        address owner;
        uint endTime;
        uint32 targetAmt;
        uint32 currAmt;
        Status status;
    }

    mapping (string => Campaign) public campaigns;
    mapping (string => mapping(address => uint32)) public fundersToAmt;
    mapping (string => bool) public isValidCampaign;

    event Cancel(string indexed nameOfCancelledCampaign);
    event Fail(string indexed nameOfFailedCampaign);
    event AbleToDelete(string indexed deletableCampaign);

    function launch(string memory name, uint duration, uint32 targetAmt) public {
        require(!isValidCampaign[name]);
        Campaign memory myCampaign = Campaign(msg.sender,block.timestamp + duration, targetAmt, 0, Status(0));
        campaigns[name] = myCampaign;
        isValidCampaign[name] = true;

    }

    function fund(string memory name) external payable {
        require(isValidCampaign[name], "Campaign does not exist!");
        require(campaigns[name].status == Status(0), "Campaign is not ongoing!");
        Campaign storage mycampaign = campaigns[name];
        mycampaign.currAmt += uint32(msg.value);
        fundersToAmt[name][msg.sender] += uint32(msg.value);
    }

    function withdraw(string memory name) external {
        Campaign storage myCampaign = campaigns[name];
        require(block.timestamp > myCampaign.endTime, "Campaign is still ongoing!");
        if(myCampaign.currAmt >= myCampaign.targetAmt){
            uint funds = myCampaign.currAmt;
            myCampaign.currAmt = 0;
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

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}

