
## Key Requirements Summarized

- **Ingest market data**: Pull buy/sell prices from each station for all tradeable items.
- **Calculate best trade options**: Taking into account cargo capacity, ISK on hand, and market dispersion.
- **Handle market complexity**: Multiple stations per solar system, many systems per region, dozens of regions.
- **Tools and APIs**: Use official EVE ESI API or services like EVEMarketer, Fuzzwork Market Data, or others for fetching real-time and historical prices.[1][2]
- **Profitability analysis**: Detect buy-low/sell-high routes and optimize per trip (volume, capital, price spread).[3][4]
- **User-friendly UI**: Easy region, system, and item filtering, clear results sorted by profit potential.

***

## 1. Fetching Eve Online Market Data

Most modern tools use the **EVE ESI API**, which allows querying market orders, historic price charts, and station/region order books. Alternatively, third-party APIs (like EVEMarketer and Fuzzwork) simplify the process with endpoint calls:

- **EVEMarketer API example** (GET, JSON):
  ```
  https://api.evemarketer.com/ec/marketstat/json?typeid=&regionlimit=
  ```
  This returns buy/sell prices and volume for a specific item and region.[2]

- **Fuzzwork** or **Adam4EVE** have similar endpoints and web tools for trade analysis.[1]

***

## 2. Market Data Analysis Logic

Your Delphi app should:
- **Download** current buy/sell orders for target item(s) in chosen regions/stations.
- **Calculate arbitrage opportunities**:
    - For each item, check:
        - Lowest sell price in Source (A)
        - Highest buy price in Destination (B)
        - Their volumes, order sizes, and station/region identities
    - Compute max units/shipping possible per trip (based on your cargo and ISK)
    - Sort results by total profit per round trip, or profit per m³
- **Include station-to-station and region-to-region options**: Don’t limit only to major hubs like Jita—include smaller stations, as done in advanced apps and spreadsheets.

***

## 3. User Interface and Filtering

Your app should allow:
- Easy region/system/station selection
- Item search and filter by volume, price, etc.
- Setting your specific ship cargo and ISK budget for simulation

## 4. Recommendations for Development

- **Delphi ESI Integration**: Use a REST client component to talk to ESI/market APIs and parse JSON market data.
- **Calculations**: Write routines for profit-per-trip, route ranking, and trade volume handling.
- **Third-party tools for inspiration**:
    - Eve Trade Terminal—market browser and profit analysis, per region/system/station (dashboard UI)
    - Evernus, Adam4EVE—trading statistics, spread filtering, historical performance
    - Fuzzwork Market Data, EVEMarketer—JSON endpoints for up-to-date prices

***

## 5. Example Data Flow

1. App downloads market order book for chosen items in all relevant stations/regions.
2. Filters out orders outside user cargo/ISK range.
3. Calculates top trade candidates: compares buy prices (in B) vs sell prices (in A), computes potential profit, sorts by best ISK/m³.
4. Outputs route and item recommendations: sorted by raw profit, profit per trip, and per volume.

***

### Further Help

[1] https://wiki.eveuniversity.org/Third-party_tools
[2] https://wiki.eveuniversity.org/API_access_to_market_data
[3] https://www.devzery.com/post/eve-markets
[4] https://www.reddit.com/r/Eve/comments/1gr45fw/from_zero_to_1_trillion_isk_the_ultimate_guide_to/
[5] https://forums.eveonline.com/t/eveterminal-io-market-analysis-discovery-tool/444259
[6] https://www.reddit.com/r/Eve/comments/1bo7l73/introducing_eveterminalio_market_analysis/
[7] https://www.youtube.com/watch?v=muvp9XhaU5c
[8] https://www.reddit.com/r/Eve/comments/c3jp7r/python_pulling_eve_market_data/
[9] https://forums.eveonline.com/t/help-with-importing-market-data-to-a-spreadsheet/348313
[10] https://www.youtube.com/watch?v=mmhVMDcQQcY
[11] https://www.youtube.com/watch?v=rGf45lIpfIE
[12] https://github.com/OrbitalEnterprises/eve-market-strategies/blob/master/eve-market-strategies.md
[13] https://www.youtube.com/watch?v=Z9gkasD1Rn0
[14] https://forums-archive.eveonline.com/topic/499873
[15] https://evetycoon.com
[16] https://www.reddit.com/r/Eve/comments/1cjkfjo/market_trading_sheettools/
[17] https://mokaam.dk
[18] https://wiki.pleaseignore.com/training:guides:marketeering
[19] https://forums.eveonline.com/t/software-eve-guru-a-best-in-breed-manufacturing-trading-tool/464297
[20] https://forums.eveonline.com/t/trading-statistics-done-right/174106
