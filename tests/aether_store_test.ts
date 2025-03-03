import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test product listing with validations",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const seller = accounts.get('wallet_1')!;
    
    // Test invalid price
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product', [
        types.ascii("Test Product"),
        types.uint(0),
        types.uint(10),
        types.ascii("Test Description")
      ], seller.address)
    ]);
    
    assertEquals(block.receipts[0].result.expectErr(), 'u105');
    
    // Test valid product
    block = chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product', [
        types.ascii("Test Product"),
        types.uint(1000),
        types.uint(10),
        types.ascii("Test Description")
      ], seller.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Test review system with purchase verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const seller = accounts.get('wallet_1')!;
    const buyer = accounts.get('wallet_2')!;
    const nonBuyer = accounts.get('wallet_3')!;
    
    // List and purchase product
    chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product', [
        types.ascii("Test Product"),
        types.uint(1000),
        types.uint(10),
        types.ascii("Test Description")
      ], seller.address),
      Tx.contractCall('aether-store', 'purchase-product', [
        types.uint(1),
        types.principal(seller.address)
      ], buyer.address)
    ]);
    
    // Try review without purchase
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'add-review', [
        types.uint(1),
        types.uint(5),
        types.ascii("Great product!")
      ], nonBuyer.address)
    ]);
    
    assertEquals(block.receipts[0].result.expectErr(), 'u107');
    
    // Add valid review
    block = chain.mineBlock([
      Tx.contractCall('aether-store', 'add-review', [
        types.uint(1),
        types.uint(5),
        types.ascii("Great product!")
      ], buyer.address)
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  }
});
