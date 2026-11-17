// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ZeppelinDrop} from "../src/ZeppelinDrop.sol";

enum ItemType { NATIVE, ERC20, ERC721, ERC1155, ERC721_WITH_CRITERIA, ERC1155_WITH_CRITERIA }
enum OrderType { FULL_OPEN, PARTIAL_OPEN, FULL_RESTRICTED, PARTIAL_RESTRICTED, CONTRACT }

struct OfferItem {
    ItemType itemType; address token; uint256 identifierOrCriteria; uint256 startAmount; uint256 endAmount;
}
struct ConsiderationItem {
    ItemType itemType; address token; uint256 identifierOrCriteria; uint256 startAmount; uint256 endAmount;
    address payable recipient;
}
struct OrderParameters {
    address offerer; address zone; OfferItem[] offer; ConsiderationItem[] consideration; OrderType orderType;
    uint256 startTime; uint256 endTime; bytes32 zoneHash; uint256 salt; bytes32 conduitKey;
    uint256 totalOriginalConsiderationItems;
}
struct OrderComponents {
    address offerer; address zone; OfferItem[] offer; ConsiderationItem[] consideration; OrderType orderType;
    uint256 startTime; uint256 endTime; bytes32 zoneHash; uint256 salt; bytes32 conduitKey; uint256 counter;
}
struct Order { OrderParameters parameters; bytes signature; }

interface ISeaport {
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey) external payable returns (bool);
    function getOrderHash(OrderComponents calldata order) external view returns (bytes32);
    function getCounter(address offerer) external view returns (uint256);
    function incrementCounter() external returns (uint256);
    function information() external view returns (string memory, bytes32, address);
}

contract SeaportForkTest is Test {
    ISeaport constant SEAPORT = ISeaport(0x0000000000000068F116a894984e2DB1123eB395);   // Seaport 1.6
    uint256 constant PRICE = 1 ether;

    ZeppelinDrop drop;
    address seller;
    uint256 sellerPk;
    address buyer = makeAddr("buyer");

    receive() external payable {}      // тест задеплоил дроп, значит, он «автор» и получает роялти

    function setUp() public {
        vm.createSelectFork("mainnet", 21_000_000);
        drop = new ZeppelinDrop(0.01 ether, 10);
        (seller, sellerPk) = makeAddrAndKey("seller");
        deal(seller, 1 ether);
        deal(buyer, 10 ether);

        vm.startPrank(seller);
        drop.mint{value: 0.01 ether}();                   // токен #0 у продавца
        drop.setApprovalForAll(address(SEAPORT), true);   // Seaport может двигать его NFT
        vm.stopPrank();
    }

    // Листинг: отдаю NFT #tokenId, хочу PRICE: часть продавцу, часть роялти автору
    function _params(uint256 tokenId) internal view returns (OrderParameters memory p) {
        (address creator, uint256 royalty) = drop.royaltyInfo(tokenId, PRICE);
        p.offerer = seller;
        p.offer = new OfferItem[](1);
        p.offer[0] = OfferItem(ItemType.ERC721, address(drop), tokenId, 1, 1);
        p.consideration = new ConsiderationItem[](2);
        p.consideration[0] = ConsiderationItem(ItemType.NATIVE, address(0), 0, PRICE - royalty, PRICE - royalty, payable(seller));
        p.consideration[1] = ConsiderationItem(ItemType.NATIVE, address(0), 0, royalty, royalty, payable(creator));
        p.orderType = OrderType.FULL_OPEN;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + 1 days;
        p.salt = 42;
        p.totalOriginalConsiderationItems = 2;
    }

    // То, что подписывается: те же поля + counter продавца
    function _components(OrderParameters memory p) internal view returns (OrderComponents memory) {
        return OrderComponents(p.offerer, p.zone, p.offer, p.consideration, p.orderType, p.startTime, p.endTime,
                               p.zoneHash, p.salt, p.conduitKey, SEAPORT.getCounter(p.offerer));
    }
    
    function _sign(OrderParameters memory p) internal view returns (bytes memory) {
        // 1. Получить хеш ордера от Seaport
        OrderComponents memory comps = _components(p);
        bytes32 orderHash = SEAPORT.getOrderHash(comps);

        // 2. Получить domain separator Seaport (EIP-712)
        // information() возвращает (version, domainSeparator, conduitController)
        (, bytes32 domainSeparator,) = SEAPORT.information();

        // 3. Построить EIP-712 digest и подписать
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, orderHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPk, digest);

        return abi.encodePacked(r, s, v);
    }
    
    function test_BuyListing() public {
        OrderParameters memory p = _params(0);
        bytes memory sig = _sign(p);

        uint256 sellerBefore = seller.balance;
        uint256 creatorBefore = address(this).balance;

        vm.prank(buyer);
        SEAPORT.fulfillOrder{value: PRICE}(Order(p, sig), bytes32(0));

        assertEq(drop.ownerOf(0), buyer);
        assertEq(seller.balance - sellerBefore, 0.95 ether);
        assertEq(address(this).balance - creatorBefore, 0.05 ether);
    }

    function test_CannotBuyTwice() public {
        OrderParameters memory p = _params(0);
        bytes memory sig = _sign(p);

        uint256 sellerBefore = seller.balance;
        uint256 creatorBefore = address(this).balance;

        vm.prank(buyer);
        SEAPORT.fulfillOrder{value: PRICE}(Order(p, sig), bytes32(0));

        assertEq(drop.ownerOf(0), buyer);
        assertEq(seller.balance - sellerBefore, 0.95 ether);
        assertEq(address(this).balance - creatorBefore, 0.05 ether);

        vm.expectRevert();
        vm.prank(buyer);
        SEAPORT.fulfillOrder{value: PRICE}(Order(p, sig), bytes32(0));
    }

    function test_IncrementCounterCancels()  public {
        OrderParameters memory p = _params(0);
        bytes memory sig = _sign(p);
        vm.prank(seller); 
        SEAPORT.incrementCounter();
        vm.expectRevert();
        SEAPORT.fulfillOrder{value: PRICE}(Order(p, sig), bytes32(0));
    }
}