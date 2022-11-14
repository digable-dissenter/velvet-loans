
pragma solidity ^0.8.17;
import "./DAI.sol";

/**
    * Basic loan contract allows to borrow DAI for a fixed period of time using ETH as collateral.
    * Fee is constant and pre-defined. The collateral will be liquidated and transferred to the lender 
		in the case of lack of payment.
 */

contract BasicLoan {

	// The structure defining the basic loan parameters
	struct LoanTerms {
		address borrower; // The address of the borrower
		address lender; // The address of the lender
		uint256 amount; // The amount of DAI borrowed
		uint256 fee; // The fee in DAI
		uint256 collateral; // The amount of ETH used as collateral
		uint256 duration; // The duration of the loan in seconds
		uint256 start; // The timestamp of the loan start
		uint256 end; // The timestamp of the loan end
	}
	LoanTerms loanterms;

	// The structure defining the loan status
	// The loan can be in 4 states: Created, Started, Ended, Liquidated

	enum LoanStatus { Created, Started, Ended, Liquidated }
	LoanStatus loanstatus;

	// Modifier that prevents some functions from being called in any other status than the one specified
	modifier onlyInState(LoanStatus expectedStatus) {
		require(loanstatus == expectedStatus, "Invalid status");
		_;
	}

	address payable public lender;
	address payable public borrower;
	address public dai;

	constructor (LoanTerms memory _loanterms, address _dai) {
		loanterms = _loanterms;
		lender = payable(msg.sender);
		dai = _dai;
		loanstatus = LoanStatus.Created;
	}

	// Transfer DAI from the lender to the contract so that we can later transfer it to the borrower in form of a loan
	// This required the lender to allow the contract to transfer DAI on its behalf
	// Will fail otherwise
	function fundLoan() public payable onlyInState(LoanStatus.Created) {
		require(msg.value == loanterms.collateral, "Invalid collateral");
		loanstatus = LoanStatus.Started;
		DAI(dai).transferFrom(
			msg.sender, 
			address(this), 
			loanterms.amount
		);
	}

	// Function to take the loan
	function takeLoanAcceptLoanTerms()
		public
		/** Collateral should be sent to the contract before the loan is taken */ 
		payable
		/** Prevents loan from being taken twice */
		onlyInState(LoanStatus.Started)
	{
		// Check that the exact amount of the collateral is transferred to the contract.
		// Will be kept in the contract until the loan is repaid or liquidated
		require(
			msg.value == loanterms.collateral,
			"Invalid collateral"
		);
		// Record the borrower address so that s/he will be able to repay the loan / unlock the collateral
		borrower = payable(msg.sender);
		loanstatus = LoanStatus.Started;
		// Transfer the actual tokens that are being loaned to the borrower
		DAI(dai).transferFrom(
			borrower, 
			address(this), 
			loanterms.amount
		);
	  
	}

	// Function to repay the loan. It can be repaid early with no fees. Borrower should allow this contract to pull tokens before calling this.
	function repay() public onlyInState(LoanStatus.Started) {
		// Check that the borrower is the one who is repaying the loan
		require(msg.sender == borrower, "Only borrower can repay the loan");
		// Check that the loan is not overdue
		require(block.timestamp < loanterms.end, "Loan overdue");
		// Transfer the loan amount + fee to the lender. If there is not enough, it will fail.
		DAI(dai).transferFrom(
			borrower, 
			lender, 
			loanterms.amount + loanterms.fee
		);
		// Transfer the collateral back to the borrower
		borrower.transfer(loanterms.collateral);
		loanstatus = LoanStatus.Ended;
	}

	// This function is to be called by the lender in case the loan is not repaid on time.
	// It will transfer the whole collateral to the lender. The collateral is expected to be
	//	more valuable than the loan so that the lender doesn't lose any money in this case.
	function liquidate() public onlyInState(LoanStatus.Started) {
		require(msg.sender == lender, "Only the lender can liquidate the loan");
		require(
			block.timestamp >= loanterms.end,
			"Loan not overdue yet"
		);
		// Send the collateral to the lender and mark the loan as liquidated
		lender.transfer(loanterms.collateral);
	}

}