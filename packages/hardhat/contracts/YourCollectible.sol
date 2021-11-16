pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "hardhat/console.sol";

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
  constructor() ERC721("SNAKES", "SNKS") {}


  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint256 public constant MAX_SUPPLY = 2000;
  uint256 public constant PRICE = 0.015 ether;

  struct Snake {
    Color color;
    string path1;
    string path2;
    uint256 bgIdx;
    uint256 thickIdx;
    uint256 thickness;
    uint256 head;
    uint256 head_mark;
    Color head_mark_color;
    uint256 snakiness;
    uint256 skin_pattern_scale;
    string skin_pattern_freq;
    uint256 skin_pattern_octaves;
  }

  struct Color {
      uint256 hue;
      uint256 saturation;
      uint256 lightness;
  }

  struct Rands {
    uint256[4] x;
    uint256[4] y;
  }
  

  function mintItem(uint256 numTokens)
      public
      payable
      virtual
  {
      require(PRICE * numTokens == msg.value, "ETH amount is incorrect");
      _mintItem(numTokens);
  }

      function _mintItem(uint256 numTokens) private {
        require(totalSupply() < MAX_SUPPLY, "No more snakes");
        require(
            totalSupply() + numTokens <= MAX_SUPPLY,
            "Not enough snakes left!"
        );
        require(numTokens > 0, "Trying to mint 0 snakes?");

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = _tokenIds.current();
            _safeMint(_msgSender(), id);
            _tokenIds.increment();
        }
    }

    function ownerMint(uint256 numTokens) public onlyOwner {
        _mintItem(numTokens);
    }

    function withdrawAll() public payable nonReentrant onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "id does not exist");

      Snake memory snk;
      string memory svg;

      string[3] memory backgroundNames = [
            "WATER",
            "DESERT",
            "SPACE"
        ];

      string[5] memory thicknessNames = [
            "SKINNY",
            "WHIMSY",
            "BASIC",
            "NOICE", 
            "THICC"
        ];

      string memory name = string(abi.encodePacked('Snake on a chain #',id.toString()));
      string memory description = string(abi.encodePacked('Every snake follows its own path (in life)'));
      (snk, svg) = generateSVGofTokenById(id);
      string memory image = Base64.encode(bytes(svg));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "attributes": [{"trait_type": "Color", "value": "',
                              toHSLString(snk.color),
                              '"},{"trait_type": "Background", "value": "',
                              backgroundNames[snk.bgIdx],
                              '"},{"trait_type": "Thickness", "value": "',
                              thicknessNames[snk.thickIdx],
                              '"},{"trait_type": "Snakiness", "value": ',
                              snk.snakiness.toString(),
                              '}], "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (Snake memory, string memory) {
    Snake memory snk;
    string memory svgdata;
    (snk, svgdata) = renderTokenById(Strings.toString(id * 6969));
    string memory svg = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" xmlns:xlink="http://www.w3.org/1999/xlink" width="500" height="500" viewBox="0 0 500 500">',
        svgdata,
      '</svg>'
    ));

    return (snk, svg);
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(string memory seed) public view returns (Snake memory, string memory) {
    Snake memory snk;
    Rands memory randVal;

    // Snake color
    snk.color = randomColor(seed, 0, 359, 40, 100, 20, 60);
    console.log("rand color %s", toHSLString(snk.color));

    // Head mark color
    snk.head_mark_color = randomColor(string(abi.encodePacked(seed, "HEADCOLOR")), 0, 359, 40, 100, 20, 60);

    // Background
    randVal.x[0] = random(seed, "backzies") % 100;
    console.log("rand bg %s", randVal.x[0]);
    if (randVal.x[0] < 30) {
      snk.bgIdx = 0;
    } else if (randVal.x[0] < 60) {
      snk.bgIdx = 1;
    } else {
      snk.bgIdx = 2;
    }    

    // Snake thickness    
    snk.thickIdx = random(seed, "thicc") % 5;
    console.log("rand thick %s", snk.thickIdx);
    if (snk.thickIdx < 1) {
      snk.thickness = 12;
      snk.head = 24;
      snk.head_mark = 10;
    } else if (snk.thickIdx < 2) {
      snk.thickness = 21;
      snk.head = 30;
      snk.head_mark = 12;
    } else if (snk.thickIdx < 3) {
      snk.thickness =30;
      snk.head = 39;
      snk.head_mark = 14;
    } else if (snk.thickIdx < 4) {
      snk.thickness = 39;
      snk.head = 42;
      snk.head_mark = 16;
    } else {
      snk.thickness = 48;
      snk.head = 48;
      snk.head_mark = 18;
    } 

    // Snakiness
    snk.snakiness = random(seed, "snakiness") % 30;
    snk.snakiness = snk.snakiness + 2;
    console.log("rand snak %s", snk.snakiness);

    // Snake pattern
    randVal.x[0] = random(seed, "patternscale") % 350;
    snk.skin_pattern_scale = randVal.x[0] + 50;
    console.log("rand scale %s", snk.skin_pattern_scale);

    randVal.x[0] = random(seed, "patternfreq") % 6;    
    string[6] memory freq = ["0.02", "0.04", "0.06", "0.08", "0.1", "0.15"];
    snk.skin_pattern_freq = freq[randVal.x[0]];
    console.log("rand freq %s", snk.skin_pattern_freq);

    randVal.x[0] = random(seed, "patternoctaves") % 3;
    snk.skin_pattern_octaves = randVal.x[0] + 2;   
    console.log("rand octaves %s", snk.skin_pattern_octaves);

    // Snake path
    
    randVal.x[0] = 250;
    randVal.y[0] = randomMaxMin(seed, "ypos0", 300, 470);
    randVal.x[1] = randomMaxMin(seed, "xpos1", 300, 470);
    randVal.y[1] = 250;
    randVal.x[2] = 250;
    randVal.y[2] = randomMaxMin(seed, "ypos2", 30, 200);
    randVal.x[3] = randomMaxMin(seed, "xpos3", 30, 200);
    randVal.y[3] = 250;

    
    snk.path1 = string(
                abi.encodePacked(
                  'M',
                  Strings.toString(randVal.x[0]),
                  ' ',
                  Strings.toString(randVal.y[0]),
                  'S',
                  Strings.toString(randVal.x[1]),
                  ',',
                  Strings.toString(randVal.y[0]),
                  ' ',
                  Strings.toString(randVal.x[1]),
                  ',',
                  Strings.toString(randVal.y[1]),
                  'S',
                  Strings.toString(randVal.x[1]),
                  ',',
                  Strings.toString(randVal.y[2]),
                  ' ',
                  Strings.toString(randVal.x[2]),
                  ',',
                  Strings.toString(randVal.y[2])
                ));

    snk.path2 = string(
                abi.encodePacked(
                  'M',
                  Strings.toString(randVal.x[2]),
                  ' ',
                  Strings.toString(randVal.y[2]),
                  'C',
                  Strings.toString(randVal.x[2] - (randVal.x[1]-randVal.x[2]) ),
                  ',',
                  Strings.toString(randVal.y[2]),
                  ' ',
                  Strings.toString(randVal.x[3]),
                  ',',
                  Strings.toString(randVal.y[2]),
                  ' ',
                  Strings.toString(randVal.x[3]),
                  ',',
                  Strings.toString(randVal.y[3]),
                  'S',
                  Strings.toString(randVal.x[3]),
                  ',',
                  Strings.toString(randVal.y[0]),
                  ' ',
                  Strings.toString(randVal.x[0]),
                  ',',
                  Strings.toString(randVal.y[0])
                ));
    

    console.log("path1 %s", snk.path1);
    console.log("path2 %s", snk.path2);

    // backgrounds
    string[3] memory backgrounds = [
            string(
                abi.encodePacked(
                  '<path fill="#0078e8" d="M0 0h500v500H0z"/><pattern id="y" width="40" height="40" patternUnits="userSpaceOnUse"><circle cx="20" cy="20" r="10" fill="#14b5ff" opacity=".2"/></pattern><filter id="m"><feTurbulence type="fractalNoise" baseFrequency=".03" numOctaves="2" seed="5515"/><feDisplacementMap in="SourceGraphic" scale="100"/></filter><g filter="url(#m)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#y)"><animateTransform attributeName="transform" type="translate" dur="5s" values="0,0; 40,40;" repeatCount="indefinite"/></rect></g>'
                )
            ),
            string(
                abi.encodePacked(
                  '<defs><linearGradient id="z" gradientTransform="rotate(90)"><stop offset="5%" stop-color="#e89f00"/><stop offset="95%" stop-color="#e8ba00"/></linearGradient></defs><path fill="#e8ba00" style="filter:url(#x)" d="M0 0h500v500H0z"/><circle cx="100" cy="100" r="100" fill="url(#z)" filter="url(#m)"/><circle cx="400" cy="400" r="100" fill="url(#z)" filter="url(#m)"/><defs><filter id="x"><feSpecularLighting result="specOut" specularExponent="12" lighting-color="#bbb"><fePointLight x="250" y="-100" z="20"><animate attributeName="x" values="250;375;600" dur="30s" repeatCount="indefinite"/><animate attributeName="y" values="-100;75;250" dur="30s" repeatCount="indefinite"/></fePointLight></feSpecularLighting><feComposite in="SourceGraphic" in2="specOut" operator="arithmetic" k1=".1" k2="1" k3="2"/></filter><filter id="m" filterUnits="userSpaceOnUse"><feTurbulence baseFrequency=".011" type="fractalNoise"/><feDisplacementMap in="SourceGraphic" scale="100"><animate attributeName="scale" begin="0s" dur="3s" values="3000;3200;2900;3050;2950" repeatCount="indefinite"/></feDisplacementMap></filter></defs>'

                )
            ),
            string(
                abi.encodePacked(
                  '<defs><linearGradient id="z" gradientTransform="rotate(90)"><stop offset="5%"/><stop offset="95%" stop-color="red"/></linearGradient></defs><path fill="#e3eee" d="M0 0h500v500H0z"/><pattern id="x" width="40" height="40" patternUnits="userSpaceOnUse"><circle cx="10" cy="10" r="3" fill="transparent" stroke="#fcfbe6" opacity=".6"/></pattern><g filter="url(#m)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#x)"><animateTransform attributeName="transform" type="translate" dur="80s" values="0,0; 0,50; 0,0" repeatCount="indefinite"/></rect></g><filter id="n" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence baseFrequency=".08" numOctaves="10" result="lol"/><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="20" xChannelSelector="R" yChannelSelector="G"/><feComposite operator="in" in2="SourceGraphic"/></filter><filter id="m"><feTurbulence type="fractalNoise" baseFrequency=".1" seed="39996"/><feDisplacementMap in="SourceGraphic" xChannelSelector="B" scale="200"/></filter>'
                )
            )
        ];

    string memory planet = '<circle cx="400" cy="100" r="50" fill="url(#z)"/><circle cx="400" cy="100" r="50" fill="url(#z)" filter="url(#n)"/>';

    // Snake
    string[4] memory snakeParts;
    snakeParts[0] = string(
                    abi.encodePacked('<defs><path stroke-dasharray="1000" pathLength="1000" fill="none" stroke-linejoin="round" stroke-dashoffset="1000" stroke-linecap="round" stroke-width="',
                    Strings.toString(snk.thickness),
                    '" id="a" d="',
                    snk.path1,
                    '"/><path stroke-dasharray="1000" pathLength="1000" fill="none" stroke-linejoin="round" stroke-dashoffset="0" stroke-linecap="round" stroke-width="',
                    Strings.toString(snk.thickness),
                    '" id="c" d="',
                    snk.path2,
                    '"/><circle cx="0" cy="0" r="',
                    Strings.toString(snk.head),
                    '" id="f"/></defs><use xlink:href="#a" filter="url(#b) url(#S)" stroke="',
                    snk.bgIdx == 2 ? "#FFF" : "#000",
                    '" opacity="',
                    snk.bgIdx == 2 ? ".3" : ".7",
                    '" transform="translate(6 6)"/><use xlink:href="#c" filter="url(#b) url(#S)" stroke="',
                    snk.bgIdx == 2 ? "#FFF" : "#000",
                    '" opacity="',
                    snk.bgIdx == 2 ? ".3" : ".7",
                    '" transform="translate(6 6)"/><use xlink:href="#a" filter="url(#b)" stroke="'
                    ));
    snakeParts[1] =               
                    string(
                    abi.encodePacked(
                    toHSLString(snk.color),
                    '"/><use xlink:href="#c" filter="url(#b)" stroke="',
                    toHSLString(snk.color),
                    '"/><use xlink:href="#a" filter="url(#d) url(#b)" stroke="',
                    toHSLString(snk.color),
                    '"/><use xlink:href="#c" filter="url(#d) url(#b)" stroke="',
                    toHSLString(snk.color),
                    '"/><g transform="translate(-250 -48)" id="h" filter="url(#b)"><g id="j" opacity="0" transform="translate(170 20)" filter="url(#e)"><line id="line1" x1="30" y1="30" x2="70" y2="30" stroke="red" stroke-width="3" /><line id="line1" x1="30" y1="30" x2="10" y2="10" stroke="red" stroke-width="3" /><line id="line1" x1="30" y1="30" x2="10" y2="50" stroke="red" stroke-width="3" /></g><use x="250" y="48" xlink:href="#f" filter="url(#b)" fill="',
                    toHSLString(snk.color),
                    '"/><use x="250" y="48" xlink:href="#f" filter="url(#d) url(#b)" fill="',
                    toHSLString(snk.color)
                    ));
    snakeParts[2] = 
                    string(
                    abi.encodePacked(               
                    '"/><path transform="rotate(45 89.216 337.812)" fill="',
                    toHSLString(snk.head_mark_color),
                    '" d="M0 0h',
                    Strings.toString(snk.head_mark),
                    'v',
                    Strings.toString(snk.head_mark),
                    'H0z"/></g>',
                    snk.bgIdx == 2 ? planet : "",
                    '<animate attributeName="stroke-dashoffset" fill="freeze" begin="0s;g.end+1s" from="0" dur="3s" xlink:href="#c" to="1000"/><animate attributeName="stroke-dashoffset" fill="freeze" begin="0s;g.end+1s" from="1000" id="i" dur="3s" xlink:href="#a" to="2000"/><animateMotion fill="freeze" begin="0s;g.end+1s" keyTimes="0 ; 1" dur="3s" xlink:href="#h" keyPoints="1 ; 0" rotate="auto" calcMode="linear"><mpath xlink:href="#a"/></animateMotion><animate attributeName="stroke-dashoffset" fill="freeze" begin="i.end" from="0" dur="3s" xlink:href="#a" to="1000"/><animate attributeName="stroke-dashoffset" fill="freeze" begin="i.end" from="1000" id="g" dur="3s" xlink:href="#c" to="2000"/><animateMotion fill="freeze" begin="i.end" keyTimes="0 ; 1" dur="3s" xlink:href="#h" keyPoints="1 ; 0" rotate="auto" calcMode="linear"><mpath xlink:href="#c"/></animateMotion><animate attributeName="opacity" fill="freeze" begin="g.end" from="0" dur="0.1s" xlink:href="#j" to="1"/><animate attributeName="opacity" fill="freeze" begin="g.end+1s" from="1" dur="0.1s" xlink:href="#j" to="0"/><defs><filter id="b" filterUnits="userSpaceOnUse"><feTurbulence baseFrequency=".35" type="fractalNoise"><animate attributeName="baseFrequency" begin="0s" dur="',
                    Strings.toString(snk.snakiness)
                    ));

    snakeParts[3] = 
                    string(
                    abi.encodePacked(   
                    's" values="0.0052;0.00753;0.0041;0.00924;0.0070;0.0052" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in="SourceGraphic" scale="50"/></filter><filter id="e" width="200%" height="200%"><feTurbulence baseFrequency=".35" type="fractalNoise"><animate attributeName="baseFrequency" begin="0s" dur="0.1s" values="0.0052;0.00753;0.0041;0.00924;0.0070;0.004" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in="SourceGraphic" scale="60"/></filter><filter id="d" filterUnits="userSpaceOnUse"><feTurbulence baseFrequency="',
                    snk.skin_pattern_freq,
                    '" type="fractalNoise" numOctaves="',
                    Strings.toString(snk.skin_pattern_octaves),
                    '"/><feDisplacementMap in="SourceGraphic" scale="',
                    Strings.toString(snk.skin_pattern_scale),
                    '"/><feComposite operator="in" in2="SourceGraphic"/></filter><filter id="S" width="200%" height="200%"><feGaussianBlur in="SourceGraphic" stdDeviation="4"/></filter></defs>'
                    ));

    string memory render = string(abi.encodePacked(
        backgrounds[snk.bgIdx],
        snakeParts[0],
        snakeParts[1],
        snakeParts[2],
        snakeParts[3]
      ));

    return (snk, render);
  }

function toHSLString(Color memory color) public pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "hsl(",
          color.hue.toString(),
          ",",
          color.saturation.toString(),
          "%,",
          color.lightness.toString(),
          "%)"
        )
      );
  }

function randomColor(
      string memory seed,
      uint256 hMin,
      uint256 hMax,
      uint256 sMin,
      uint256 sMax,
      uint256 lMin,
      uint256 lMax
  ) internal pure returns (Color memory) {
      return
          Color(
              randomMaxMin(seed, "hue", hMin, hMax),
              randomMaxMin(seed, "saturation", sMin, sMax),
              randomMaxMin(seed, "lightness", lMin, lMax)
          );
  }

  function randomMaxMin(
      string memory seed,
      string memory key,
      uint256 min,
      uint256 max
  ) internal pure returns (uint256) {
      return
          (uint256(keccak256(abi.encodePacked("mainnet", seed, key))) % (max - min)) +
          min;
  }

  function random(string memory seed, string memory key)
      internal
      pure
      returns (uint256)
  {
      return uint256(keccak256(abi.encodePacked(key, seed)));
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

}
