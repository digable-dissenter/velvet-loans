const Loan = artifacts.require('VelvetLoans');
 
contract('Test new basic loan', (borrower) => {
  it('should store any borrower information', async () => {
    const LoanInstance = await Loan.new();
    // Set information "RSK"
    await LoanInstance.fundLoan();
    // Get information value
    const storedData = await LoanInstance.takeLoanAcceptLoanTerms();
    assert.equal(storedData, "RSK", 'The information RSK was not stored.');
  });
});