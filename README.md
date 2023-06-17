# Crowdfund Smart Contract

This smart contract is a CrowdFundManager that allows users to create and manage crowdfunding campaigns.It provides transparency as anyone is able to view the amount contributed by the funders to a certain campaign. The absence of a middleman who takes a percentage of the total amt raised is also a benfit for the entity that is raising funds.

# Functionalities

1)The contract defines an enum called Status that represents the status of a campaign. 
The possible statuses are Ongoing, Cancelled, Success, and Failed.

2)It defines a struct called Campaign that holds the attributes of a campaign, including the owner address, end time, target amount, current amount, and status.

3)The contract uses mappings to store campaign information. 
    -"campaigns" mapping maps the name of a campaign (string) to its corresponding Campaign struct.
    -"fundersToAmt" mapping maps a campaign name and funder address to the contributed amount. 
    -"isValidCampaign" mapping is used to track the existence of a campaign.
 
 4)The contract emits events to notify the front-end about the outcome of campaigns. 
    The events include:
      -"Cancel" (when a campaign is cancelled),
      -"Fail" (when a campaign fails),
      -"AbleToDelete" (a campaign can only be deleted if the contributed amt has been withdrawn when it is a success or refund has been complete when                        it is cancelled by owner or when it has failed).
      
## Launch function
    It takes a name, duration, and target amount as input. It checks if the campaign name is unique and then creates a new Campaign struct with the       provided information.
    
## Fund function
     Verifies that the campaign exists and is ongoing. The contributed amount is added to the current        amount of the campaign, and the funder's      contribution is tracked in the fundersToAmt mapping.

## Withdraw function
    Anyone is able to call the withdraw function(not just the owner who launched the campaign) but the funds will be transferred to the owner             only!This function can only be called when the campaign has ended.
    
    There are 2 outcomes when the campaign ends:
        1)Success if the currAmt is >= targetAmt:
            -Transfer funds to owner and update the status to success
            -emit AbleToDelete event to let ppl know that this campaign can be deleted
        2)Failed if currAmt < targetAmt:
            -update status to Failes and emit the fail event so that funders are notified to get refund(by calling the refund function)

## CancelCampaign function
    The cancelCampaign function allows the owner of a campaign to cancel it before the end time. The campaign status is set to Cancelled, and the         "Cancel" event is emitted to let funders know that they can get a refund(by calling the refund function).
    
## Refund function
   The refund function allows contributors to withdraw their funds if the campaign has been cancelled or failed. It checks that the campaign status      is either Cancelled or Failed and the sender has contributed to the campaign. The contributed amount is returned to the sender, and if the            current amount of the campaign becomes zero, the "AbleToDelete" event is emitted.

## DeleteCampaign function
    -Check if the campaign name is valid and the status is not ongoing as only campaigns that are successful(with all funds withdrawn)/cancelled or        failed(with all funds refunded) can be deleted.
    -Delete the campaign from the 'campaigns' mapping 
    -set the campaign' name as invalid 
    
 
## Remarks
    - The only authorisation that an owner of a campaign/the person who launched the campaign has is to cancel the campaign while it is ongoing.
      Any external party is able to call Withdraw function.This ensures that the owner releases the funds if the campaign has failed instead of             holding onto it.
      
## Security concerns
    - An attacker could potentially execute malicious code in their fallback or receive functions, which could lead to reentrancy attacks. By re-           entering the refund function before the fundersToAmt[name][msg.sender] is updated, the attacker could repeatedly withdraw funds from the               contract.
    -This was mitigated by updating the balance first before transferring the funds(the funds are transferred at the last line).
    
    
    
    
    
    
    
    
    
    
    
      
