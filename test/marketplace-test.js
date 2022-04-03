const { expect, assert, use } = require('chai');
const {BigNumber: BN } = require('ethers');
const { ethers, waffle} = require("hardhat");
const provider = waffle.provider;


describe('Marketplace Contract', function () {

	let token721;
	let token1155;
	let marketplace;
  let nonerc721token;
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

	beforeEach(async function () {

		[owner, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9, addr10] = await ethers.getSigners();

		Token721 = await hre.ethers.getContractFactory('Token721');
		token721 = await Token721.deploy("test-721", "test-721");
		await token721.deployed();

    Token1155 = await hre.ethers.getContractFactory('Token1155');
		token1155 = await Token1155.deploy();
		await token1155.deployed();

    NonERC721Token = await hre.ethers.getContractFactory('NonERC721Token');
		nonerc721token = await NonERC721Token.deploy("fake-721", "fake-721");
		await nonerc721token.deployed();

    Marketplace = await hre.ethers.getContractFactory('Marketplace');
		marketplace = await Marketplace.deploy();
		await marketplace.deployed();


    let uri721 = ["https://testing/1.json", "https://testing/2.json", "https://testing/3.json", "https://testing/4.json", "https://testing/5.json"]
    let address721 = [owner.address, addr2.address, addr3.address, addr4.address, addr5.address]
    await token721.batchMintTo(uri721, address721)

    await token1155.mintTo(1, owner.address, 1);
    await token1155.mintTo(2, addr2.address, 1);
    await token1155.mintTo(3, addr3.address, 5);
    await token1155.mintTo(4, addr4.address, 10);
    await token1155.mintTo(5, addr5.address, 50);

	});


  describe("Deployment", function () {

    it("Should set the right owner for token721", async function () {
        expect(await token721.owner()).to.equal(owner.address);
    });

    it("Should set the right owner for token1155", async function () {
      expect(await token1155.owner()).to.equal(owner.address);
    });

    it("Should set the right owner for marketplace", async function () {
      expect(await marketplace.owner()).to.equal(owner.address);
    });

  });


  describe("newOffer", function () {

    beforeEach(async function () {
			await token721.approve(marketplace.address, 1)
      await marketplace.newOffer(token721.address, 1, 1, 5)
		});


    it("Should add a new 721 offer with the correct detail", async function () {

      let obj = await marketplace.offer(0)

      expect(obj[0]).to.equal(owner.address); 
			expect(obj[1]).to.equal(true); 
			expect(obj[2]).to.equal(token721.address); 
			expect(obj[3]).to.equal(1); 
			expect(obj[4]).to.equal(1);
			expect(obj[5]).to.equal(5); 
      expect(obj[6]).to.equal(false); 
      expect( await marketplace.numberOfOffer() ).to.equal(1); 

    });


    it("Should add a new 1155 offer with correct detail", async function () {

      await token1155.connect(addr5).setApprovalForAll(marketplace.address, true)
      await marketplace.connect(addr5).newOffer(token1155.address, 5, 30, 500)

      let obj = await marketplace.offer(1)
      expect(obj[0]).to.equal(addr5.address); 
			expect(obj[1]).to.equal(false); 
			expect(obj[2]).to.equal(token1155.address); 
			expect(obj[3]).to.equal(5); 
			expect(obj[4]).to.equal(30);
			expect(obj[5]).to.equal(500); 
      expect(obj[6]).to.equal(false); 
      expect( await marketplace.numberOfOffer() ).to.equal(2); 

    });


    it("Should NOT add a offer due to having zero address", async function () {
      await expect(
				marketplace.newOffer(ZERO_ADDRESS, 1, 1, 5)
			).to.be.revertedWith('Marketplace::notZeroAddress: zero address is not allowed');
    });

    it("Should NOT add a offer due to having zero amount", async function () {
      await expect(
				marketplace.newOffer(token721.address, 1, 0, 5)
			).to.be.revertedWith('Marketplace::notZeroAmount: cannot be zero');
    });

    it("Should NOT add a offer due to having zero price", async function () {
      await expect(
				marketplace.newOffer(token721.address, 1, 1, 0)
			).to.be.revertedWith('Marketplace::notZeroAmount: cannot be zero');
    });

    it("Should NOT add a offer due to amount not being 1 in the case of ERC721", async function () {
      await expect(
				marketplace.newOffer(token721.address, 1, 2, 25)
			).to.be.revertedWith('Marketplace::newOffer: amount must be 1 in the case of ERC721');
    });


    it("Should NOT add a offer due to a unsuppported token type", async function () {
      await expect(
				marketplace.newOffer(nonerc721token.address, 1, 2, 25)
			).to.be.revertedWith("Transaction reverted: function selector was not recognized and there's no fallback function");
    });


  });


  describe("buy", function () {

    beforeEach(async function () {
			await token721.approve(marketplace.address, 1)
      await marketplace.newOffer(token721.address, 1, 1, 100)

      await token1155.connect(addr5).setApprovalForAll(marketplace.address, true)
      await marketplace.connect(addr5).newOffer(token1155.address, 5, 30, 500)

		});


    it("Should buy the 721 NFT", async function () {
      let sellerPreviousBalance = await provider.getBalance(owner.address)
      await marketplace.connect(addr2).buy(0, { value: 100 })
      let sellerCurrentBalance = await provider.getBalance(owner.address)
      expect( await token721.ownerOf(1) ).to.equal(addr2.address); 
      let obj = await marketplace.offer(0)
      expect( obj[6] ).to.equal(true);
      expect( sellerCurrentBalance.sub(sellerPreviousBalance) ).to.equal( BN.from("99") ); 
    });


    it("Should buy the 1155 NFT", async function () {
      await marketplace.connect(addr2).buy(1, { value: 500 })
      expect( await token1155.balanceOf(addr2.address, 5) ).to.equal(30); 
      expect( await token1155.balanceOf(addr5.address, 5) ).to.equal(20); 
    });


    it("Should NOT buy the NFT due to non-existing offer", async function () {
      await expect(
        marketplace.connect(addr2).buy(2, { value: 100 })
      ).to.be.revertedWith("Marketplace::isValidOffer: The offer doesn't exist");
    });


    it("Should NOT buy the NFT due to low price", async function () {
      await expect(
        marketplace.connect(addr2).buy(0, { value: BN.from("99") })
      ).to.be.revertedWith("Marketplace::buy: The buying price is below the offer price");
    });


    it("Should NOT buy the NFT due to nft already sold", async function () {
      await marketplace.connect(addr2).buy(0, { value: 100 })
      await expect(
        marketplace.connect(addr3).buy(0, { value: 100 })
      ).to.be.revertedWith("arketplace::buy: Already sold");
    });

  });

  describe("editOffer", function () {

    beforeEach(async function () {
			await token721.approve(marketplace.address, 1)
      await marketplace.newOffer(token721.address, 1, 1, 100)
		});


    it("Should edit the NFT price", async function () {
      await marketplace.editOffer(0, 77);
      let obj = await marketplace.offer(0)
			expect(obj[5]).to.equal(77); 
    });


    it("Should NOT edit the NFT due to not being a owner", async function () {
      await expect(
        marketplace.connect(addr2).editOffer(0, 77)
      ).to.be.revertedWith("Marketplace::editOffer: Not the owner");
    });


    it("Should NOT edit the NFT due to NFT being sold", async function () {
      await marketplace.connect(addr2).buy(0, { value: 100 })
      await expect(
        marketplace.editOffer(0, 77)
      ).to.be.revertedWith("Marketplace::editOffer: Already sold");
    });


  });


  describe("cancelOffer", function () {

    beforeEach(async function () {
			await token721.approve(marketplace.address, 1)
      await marketplace.newOffer(token721.address, 1, 1, 100)

      await token1155.connect(addr5).setApprovalForAll(marketplace.address, true)
      await marketplace.connect(addr5).newOffer(token1155.address, 5, 30, 500)
		});


    it("Should cancel the 721 offer", async function () {
      await marketplace.cancelOffer(0);
      let obj = await marketplace.offer(0)
      expect(obj[6]).to.equal(true); 
      expect( await token721.ownerOf(1) ).to.equal(owner.address); 
    });

    it("Should cancel the 1155 offer", async function () {
      await marketplace.connect(addr5).cancelOffer(1);
      let obj = await marketplace.offer(1)
      expect(obj[6]).to.equal(true); 
      expect( await token1155.balanceOf(addr5.address, 5) ).to.equal(50); 
    });


    it("Should NOT cancel the offer due to not being a owner", async function () {
      await expect(
        marketplace.connect(addr2).cancelOffer(0)
      ).to.be.revertedWith("Marketplace::cancelOffer: Not the owner");
    });


    it("Should NOT cancel the offer due to already sold", async function () {
      await marketplace.connect(addr2).buy(0, { value: 100 })
      await expect(
        marketplace.cancelOffer(0)
      ).to.be.revertedWith("Marketplace::cancelOffer: Already sold");
    });


  });


  describe("batchGetOffer", function () {

    beforeEach(async function () {

			await token721.approve(marketplace.address, 1)
      await token721.connect(addr2).approve(marketplace.address, 2)
      await token721.connect(addr3).approve(marketplace.address, 3)
      await token721.connect(addr4).approve(marketplace.address, 4)
      await token721.connect(addr5).approve(marketplace.address, 5)

      await marketplace.newOffer(token721.address, 1, 1, 100)
      await marketplace.connect(addr2).newOffer(token721.address, 2, 1, 100)
      await marketplace.connect(addr3).newOffer(token721.address, 3, 1, 100)
      await marketplace.connect(addr4).newOffer(token721.address, 4, 1, 100)
      await marketplace.connect(addr5).newOffer(token721.address, 5, 1, 100)

		});


    it("Should show 5 offers", async function () {
      expect(await marketplace.numberOfOffer() ).to.equal(5); 
    });


    it("Should show batch get 5 offers", async function () {
      let arr = await marketplace.batchGetOffer(0,4)
      expect( arr.length ).to.equal(5); 
    });


  });


  describe("commission", function () {

    beforeEach(async function () {

			await token721.approve(marketplace.address, 1)
      await token721.connect(addr2).approve(marketplace.address, 2)
      await token721.connect(addr3).approve(marketplace.address, 3)
      await token721.connect(addr4).approve(marketplace.address, 4)
      await token721.connect(addr5).approve(marketplace.address, 5)

      await marketplace.newOffer(token721.address, 1, 1, 100)
      await marketplace.connect(addr2).newOffer(token721.address, 2, 1, 100)
      await marketplace.connect(addr3).newOffer(token721.address, 3, 1, 100)
      await marketplace.connect(addr4).newOffer(token721.address, 4, 1, 100)
      await marketplace.connect(addr5).newOffer(token721.address, 5, 1, 100)

      await marketplace.connect(addr6).buy(0, { value: 100})
      await marketplace.connect(addr7).buy(1, { value: 100})
      await marketplace.connect(addr8).buy(2, { value: 100})
      await marketplace.connect(addr9).buy(3, { value: 100})
      await marketplace.connect(addr10).buy(4, { value: 100})
     
		});

    it("Should show the correct commission", async function () {
      expect( await marketplace.commission() ).to.equal( BN.from("5")); 
    });

  });




  describe("withdrawCommission", function () {

    beforeEach(async function () {

			await token721.approve(marketplace.address, 1)
      await token721.connect(addr2).approve(marketplace.address, 2)
      await token721.connect(addr3).approve(marketplace.address, 3)
      await token721.connect(addr4).approve(marketplace.address, 4)
      await token721.connect(addr5).approve(marketplace.address, 5)

      await marketplace.newOffer(token721.address, 1, 1, 100)
      await marketplace.connect(addr2).newOffer(token721.address, 2, 1, 100)
      await marketplace.connect(addr3).newOffer(token721.address, 3, 1, 100)
      await marketplace.connect(addr4).newOffer(token721.address, 4, 1, 100)
      await marketplace.connect(addr5).newOffer(token721.address, 5, 1, 100)

		});

    it("Should withdraw the commission", async function () {

      await marketplace.connect(addr6).buy(0, { value: 100})
      await marketplace.connect(addr7).buy(1, { value: 100})
      await marketplace.connect(addr8).buy(2, { value: 100})
      await marketplace.connect(addr9).buy(3, { value: 100})
      await marketplace.connect(addr10).buy(4, { value: 100})

      await marketplace.withdrawCommission()
      expect( await marketplace.commission() ).to.equal( BN.from("0") ); 
    });


    it("Should NOT withdraw the commission due to zero balance", async function () {
      await expect(
        marketplace.withdrawCommission()
      ).to.be.revertedWith("Marketplace::withdrawCommission: No balance");
    });

  });

	after(async function () {});
});
