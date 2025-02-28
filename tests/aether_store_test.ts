import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test product listing",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const seller = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product', [
        types.ascii("Test Product"),
        types.uint(1000),
        types.uint(10),
        types.ascii("Test Description")
      ], seller.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    const response = chain.callReadOnlyFn(
      'aether-store',
      'get-product',
      [types.uint(1)],
      seller.address
    );
    
    response.result.expectOk().expectSome();
  }
});

Clarinet.test({
  name: "Test product purchase",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const seller = accounts.get('wallet_1')!;
    const buyer = accounts.get('wallet_2')!;
    
    // First list a product
    chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product', [
        types.ascii("Test Product"),
        types.uint(1000),
        types.uint(10),
        types.ascii("Test Description")
      ], seller.address)
    ]);
    
    // Then purchase it
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'purchase-product', [
        types.uint(1),
        types.principal(seller.address)
      ], buyer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify inventory reduced
    const response = chain.callReadOnlyFn(
      'aether-store',
      'get-product',
      [types.uint(1)],
      buyer.address
    );
    
    const product = response.result.expectOk().expectSome();
    assertEquals(product.inventory, 9);
  }
});

Clarinet.test({
  name: "Test review system",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const seller = accounts.get('wallet_1')!;
    const buyer = accounts.get('wallet_2')!;
    
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
    
    // Add review
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'add-review', [
        types.uint(1),
        types.uint(5),
        types.ascii("Great product!")
      ], buyer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check seller rating
    const response = chain.callReadOnlyFn(
      'aether-store',
      'get-seller-rating',
      [types.principal(seller.address)],
      buyer.address
    );
    
    const rating = response.result.expectOk();
    assertEquals(rating['average-rating'], 5);
    assertEquals(rating['total-sales'], 1);
  }
});
