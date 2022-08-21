import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, constants } from "ethers";
import { ethers } from 'hardhat';
import { TransferSafeRouter } from "../typechain-types";
import { InvoiceStruct } from "../typechain-types/contracts/TransferSafeRouter";

const TEST_ADDRESS = '0x16531e83559cebad5d6d5269f91e7995aaded6de';
const CHAIN_ID = 80001;
const INVOICE_ID = '123';
const INITIAL_INVOICE: InvoiceStruct = {
  amount: BigNumber.from(1000),
  availableTokenTypes: [],
  balance: BigNumber.from(1000),
  confirmDate: BigNumber.from(1000),
  createdDate: BigNumber.from(1000),
  depositDate: BigNumber.from(1000),
  deposited: true,
  exist: false,
  fee: BigNumber.from(999),
  id: INVOICE_ID,
  instant: false,
  isNativeToken: true,
  paid: true,
  paidAmount: BigNumber.from(1000),
  receipientAddress: constants.AddressZero,
  receipientEmail: 'test@gmail.com',
  receipientName: '',
  ref: 'test',
  refundDate: BigNumber.from(1000),
  refunded: true,
  refundedAmount: BigNumber.from(1000),
  releaseLockDate: BigNumber.from(1000),
  releaseLockTimeout: BigNumber.from(1000),
  senderAddress: constants.AddressZero,
  tokenType: constants.AddressZero
}

describe("Token contract", function () {
  let router: TransferSafeRouter;
  let owner: SignerWithAddress;

  beforeEach(async () => {
    const [newOowner] = await ethers.getSigners();
    owner = newOowner;
    const TransferSafeRouter = await ethers.getContractFactory("TransferSafeRouter");
    router = await TransferSafeRouter.deploy(CHAIN_ID);
    await router.deployed();
  });

  it("Should have proper initial values", async function () {
    expect(await router.getFee()).to.equal(BigNumber.from(10));
    await router.setFee(BigNumber.from(20));
    expect(await router.getFee()).to.equal(BigNumber.from(20));
  });

  it('should create invoice with proper init values', async () => {
    await router.createInvoice(INITIAL_INVOICE);
    const createdInvoice = await router.getInvoice(INVOICE_ID);

    expect(createdInvoice.id).to.equal(INVOICE_ID);
    expect(createdInvoice.amount).to.equal(INITIAL_INVOICE.amount);
    expect(createdInvoice.availableTokenTypes).to.deep.equal([]);
    expect(createdInvoice.confirmDate).to.equal(BigNumber.from(0));
    expect(createdInvoice.depositDate).to.equal(BigNumber.from(0));
    expect(createdInvoice.deposited).to.equal(false);
    expect(createdInvoice.exist).to.equal(true);
    expect(createdInvoice.fee).to.equal(BigNumber.from(INITIAL_INVOICE.amount).div(100));
    expect(createdInvoice.instant).to.equal(INITIAL_INVOICE.instant);
    expect(createdInvoice.isNativeToken).to.equal(false);
    expect(createdInvoice.paid).to.equal(false);
    expect(createdInvoice.paidAmount).to.equal(constants.Zero);
    expect(createdInvoice.receipientAddress).to.equal(owner.address);
    expect(createdInvoice.receipientEmail).to.equal(INITIAL_INVOICE.receipientEmail);
    expect(createdInvoice.ref).to.equal(INITIAL_INVOICE.ref);
    expect(createdInvoice.refundDate).to.equal(constants.Zero);
    expect(createdInvoice.refunded).to.equal(false);
    expect(createdInvoice.refundedAmount).to.equal(constants.Zero);
    expect(createdInvoice.releaseLockTimeout).to.equal(INITIAL_INVOICE.releaseLockTimeout);
    expect(createdInvoice.senderAddress).to.equal(constants.AddressZero);
    expect(createdInvoice.tokenType).to.equal(constants.AddressZero);
  });
});