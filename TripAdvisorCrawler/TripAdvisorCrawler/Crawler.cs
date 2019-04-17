using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using HtmlAgilityPack;
using Newtonsoft.Json;
using System.Web;
using System.Threading;
using OpenQA.Selenium.Chrome;
using OpenQA.Selenium;
using MongoDB.Bson;
using MongoDB.Driver;

namespace TripAdvisorCrawler
{
    public class Crawler
    {
        private static int CLICK_WAIT = 4000;
        private static int MAX_REVIEWS = 500;
        private string seed;
        private string tripadvisor = "https://tripadvisor.com";
        public List<POI> results = new List<POI>();
        public Dictionary<string, User> users = new Dictionary<string, User>();
        public string tripType;
        private ChromeOptions chromeOptions = new ChromeOptions();
        public ChromeDriver driver = null;
        //public ChromeDriver driver = new ChromeDriver("C:/Users/marku/Desktop");
        public HtmlWeb web = new HtmlWeb();
        public HtmlDocument doc;
        public MongoClient dbClient = new MongoClient("mongodb://127.0.0.1:27017");
        private int reviewCounter = 0;
        private int idCounterPoi = 0;

        public Crawler(string seed)
        {
            this.seed = seed;
            doc = web.Load(seed);
            var chromeOptions = new ChromeOptions();
            chromeOptions.AddArguments("--headless");
            chromeOptions.AddArguments("--disable-gpu","--log-level=3");
            
            driver = new ChromeDriver("C:/Users/User/Documents/AAU/P8Project/TripAdvisorCrawler/TripAdvisorCrawler", chromeOptions);
        }

        public void Crawl()
        {
            //ProcessTop30Attractions(seed);
            //ProcessTop30RestaurantsPage("https://www.tripadvisor.com/Restaurants-g186338-London_England.html#EATERY_OVERVIEW_BOX");
            ProcessOtherAttractions("https://www.tripadvisor.com/Attractions-g186338-Activities-oa30-London_England.html");
            //ProcessOtherRestaurants("https://www.tripadvisor.com/Restaurants-g186338-oa30-London_England.html#EATERY_OVERVIEW_BOX");

        }

        public void ProcessTop30Attractions(string pageUrl)
        {

            var attractionElements = doc.DocumentNode.SelectNodes("//li[contains(@class,'attractions-attraction-overview-main-TopPOIs')]");
            foreach (var element in attractionElements)
            {
                //var e = ele.ChildNodes[1].ChildNodes.Where(x => x.Name == "li").ToList()[attIndex].ChildNodes[1].ChildNodes[2];
                var attLink = element.InnerHtml.Split('\"')[5];

                var poi = ProcessAttraction(attLink);
                Console.WriteLine();
                Console.WriteLine("===== Fetching Reviews: " + poi.name +" :: " + DateTime.Now );
                ProcessReviews(poi, driver, attLink);

            }
        }

        public void ProcessOtherAttractions(string pageUrl)
        {
            doc = web.Load(pageUrl);
            var noPages = Convert.ToInt32(doc.DocumentNode.SelectSingleNode("//*[@id='FILTERED_LIST']/div[36]/div/div/div/a[6]").InnerText.Trim());
            int startIndex = 30;
            for (int i = 0; i < noPages; i++)
            {
                if(i != 0) doc = web.Load(pageUrl);

                var attElements = doc.DocumentNode.SelectNodes("//div[contains(@id,'ATTR_ENTRY')]");
                foreach (var element in attElements)
                {
                    var attLink = element.ChildNodes[1].ChildNodes[1].ChildNodes[1].ChildNodes[3].InnerHtml.Split('\"')[1];
                    var poi = ProcessAttraction(attLink);
                    poi.id = idCounterPoi;
                    idCounterPoi++;
                    Console.WriteLine();
                    Console.WriteLine("===== Fetching Reviews: " + poi.name + " :: " + DateTime.Now);
                    ProcessReviews(poi, driver, attLink);
                    Console.WriteLine("=== Saving in DB ===");
                    SavePOIReviewsToDB(poi);
                    
                }
                pageUrl = pageUrl.Replace(("oa" + (i + 1) * startIndex), "oa" + ((i + 2) * startIndex));
                
            }
            
            
        }


        private void SavePOIReviewsToDB(POI poi)
        {
            var db = dbClient.GetDatabase("TripAdvisor");
            var collection = db.GetCollection<BsonDocument>("Reviews");
            collection.InsertManyAsync(poi.reviews.Select(r => r.ToBsonDocument()));

            collection = db.GetCollection<BsonDocument>("POI");
            collection.InsertOneAsync(poi.ToBsonDocument());

        }

        private POI ProcessAttraction(string link)
        {
            //Load attraction page
            var innerDoc = web.Load(tripadvisor + link);
            //Find script containing JSON data about attraction
            var contextScriptNode = innerDoc.DocumentNode.SelectNodes("//script")[1];
            dynamic array = JsonConvert.DeserializeObject(contextScriptNode.InnerHtml);
            //Create new POI and populate from JSON
            POI newPOI = new POI();
            newPOI.name = array["name"];
            newPOI.imgURL = array["image"];
            newPOI.avgRating = Convert.ToDouble(array["aggregateRating"]["ratingValue"]);
            newPOI.address = array["address"]["streetAddress"];
            newPOI.city = array["address"]["addressLocality"];
            newPOI.openingshours = new Dictionary<string, List<string>>();
            //Gets first div with class 'detail' containing the category
            newPOI.category = innerDoc.DocumentNode.SelectNodes("//div[contains(@class,'detail')]")[0].InnerText;
            //Checks for existence of opening times
            var openingExist = innerDoc.DocumentNode.SelectNodes("//div[@class='hoursAll hidden']");
            if (openingExist != null)
            {
                //Adds opening times
                var openingTimesDiv = openingExist[0].ChildNodes[0];
                int lastDayIndex = 0;
                for (int i = 0; i < openingTimesDiv.ChildNodes.Count; i++)
                {
                    if (Char.IsNumber(openingTimesDiv.ChildNodes[i].InnerText.First()))
                    {
                        newPOI.openingshours[openingTimesDiv.ChildNodes[lastDayIndex].InnerText].Add(openingTimesDiv.ChildNodes[i].InnerText);

                    }

                    else
                    {
                        newPOI.openingshours.Add(openingTimesDiv.ChildNodes[i].InnerText, new List<string>());
                        lastDayIndex = i;
                    }

                    i++;
                }
            }
            return newPOI;
        }

        private void ProcessReviews(POI newPOI, ChromeDriver driver, string attractionLink)
        {
            newPOI.reviews = new List<Review>();            
            //Review handling
            var noPages = 1;
            var alteredDoc = new HtmlDocument();
            //Go to attraction page
            driver.Navigate().GoToUrl(tripadvisor + attractionLink);
            //Check language box for all languages
            //*[@id="taplc_detail_filters_rr_resp_0"]/div/div[1]/div/div[2]/div[4]/div/div[2]/div[1]/div[1]/label

            IWebElement languageCheckBox = null;
            try
            {
                languageCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[4]/div/div[2]/div[1]/div[1]/label");

            }
            catch (NoSuchElementException e)
            {
                try
                {
                    languageCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[4]/div/div[2]/div[1]/div[1]/label");
                }
                catch (Exception h)
                {
                    throw;
                }
                
            }

            languageCheckBox.Click();
            Thread.Sleep(CLICK_WAIT);
            IWebElement tripCheckBox = null;
            
            for (int i = 0; i < 5; i++)
            {
                if (i == 0)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[1]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripType = "family";
                    Console.WriteLine("-- Processing Family reviews :: " + DateTime.Now);
                }
                else if (i == 1)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[1]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[2]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripType = "couple";
                    Console.WriteLine("-- Processing Couple reviews :: " + DateTime.Now);
                }
                else if (i == 2)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[2]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[3]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripType = "alone";
                    Console.WriteLine("-- Processing Alone reviews :: " + DateTime.Now);
                }
                else if (i == 3)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[3]/label");

                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[4]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripType = "business";
                    Console.WriteLine("-- Processing Business reviews :: " + DateTime.Now);
                }
                else if (i == 4)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[4]/label");

                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_ar_responsive_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[5]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripType = "friends";
                    Console.WriteLine("-- Processing Friend reviews :: " + DateTime.Now);
                }

                alteredDoc.LoadHtml(driver.PageSource);

                var pageNodes = alteredDoc.DocumentNode.SelectNodes("//a[contains(@class, 'pageNum last taLnk')]");
                if (pageNodes != null) noPages = Convert.ToInt32(pageNodes[0].InnerText);
                else noPages = 1;

                if (noPages > MAX_REVIEWS) noPages = MAX_REVIEWS;

                noPages = 2;
                for (int h = 0; h < noPages; h++)
                {
                    if (h != 0)
                    {
                        var insIndex = attractionLink.IndexOf("Reviews") + 8;
                        attractionLink = attractionLink.Insert(insIndex, "or" + h * 10 + "-");
                        driver.Navigate().GoToUrl(tripadvisor + attractionLink);
                        alteredDoc.LoadHtml(driver.PageSource);
                    }

                    var reviewNodes = alteredDoc.DocumentNode.SelectNodes("//div[contains(@class,'rev_wrap')]");
                    int k = 0;
                    foreach (var item in reviewNodes)
                    {
                        string userID = null;
                        try
                        {
                            userID = item.SelectNodes("//div[@class='member_info']")[k].ChildNodes[0].Id.Substring(4).Split('-')[0];
                        }
                        catch (Exception e)
                        {
                            Console.WriteLine("Invalid user found -> SKIPPING");
                            Console.WriteLine(e.Message);
                            k++;
                            continue;
                        }


                        var newReview = new Review();
                        newReview.id = reviewCounter;
                        newReview.subject = newPOI;
                        reviewCounter++;
                        if (users.ContainsKey(userID))
                        {
                            //users[userID].given_reviews.Add(newReview.id);
                            newReview.author = users[userID];
                        }
                        else
                        {
                            var newUser = new User();
                            newUser.uid = userID;
                            users.Add(userID, newUser);
                            //newUser.given_reviews = new List<int>();
                            //newUser.given_reviews.Add(newReview.id);
                            newReview.author = newUser;
                        }
                        var spanContainer = item.SelectNodes("//div[contains(@class,'rev_wrap ui_columns is-multiline')]")[k];
                        var rating = Char.GetNumericValue(spanContainer.ChildNodes[1].InnerHtml.Split('_')[3][0]);
                        newReview.rating = rating;
                        newReview.month_visited = item.SelectNodes("//div[@class='prw_rup prw_reviews_stay_date_hsx']")[k].InnerText.Split(':')[1].Trim();
                        
                        newReview.company = tripType;


                        newPOI.reviews.Add(newReview);
                        k++;

                    }
                    Console.WriteLine("Page: " + (h + 1) + "/" + noPages);
                    Thread.Sleep(1000);
                }
                Console.WriteLine("Finished triptype: " + tripType + " :: " + DateTime.Now);
                Console.WriteLine();
            }
            Console.WriteLine(" ===== Finished processing:" + newPOI.name + " =====");
            Console.WriteLine();
            results.Add(newPOI);
        }



        //============ Restaurant Processing =====================

        public void ProcessTop30RestaurantsPage(string pageUrl)
        {
            HtmlWeb web = new HtmlWeb();
            HtmlDocument doc = web.Load(pageUrl);
            var elements = doc.DocumentNode.SelectNodes("//div[contains(@id,'eatery_')]");

            foreach (var element in elements)
            {
                var restLink = element.ChildNodes[1].InnerHtml.Split('\"')[3];
                var poi = ProcessRestaurant(restLink);
                Console.WriteLine("===== Fetching reviews: " + poi.name + " =====");
                ProcessRestaurantReviews(poi, restLink);
            }
        }

        public void ProcessOtherRestaurants(string pageUrl)
        {
            doc = web.Load(pageUrl);
            var noPages = Convert.ToInt32(doc.DocumentNode.SelectSingleNode("//*[@id='EATERY_LIST_CONTENTS']/div[2]/div/div/a[6]").InnerText.Trim());
            int startIndex = 30;
            for (int i = 0; i < noPages; i++)
            {
                if (i != 0) doc = web.Load(pageUrl);

                var attElements = doc.DocumentNode.SelectNodes("//div[contains(@id,'eatery_')]");
                foreach (var element in attElements)
                {
                    var attLink = element.ChildNodes[1].InnerHtml.Split('\"')[3];
                    var poi = ProcessAttraction(attLink);
                    Console.WriteLine();
                    Console.WriteLine("===== Fetching Reviews: " + poi.name + " :: " + DateTime.Now);
                    ProcessRestaurantReviews(poi, attLink);
                }
                pageUrl = pageUrl.Replace(("oa" + (i + 1) * startIndex), "oa" + ((i + 2) * startIndex));

            }
        }

        private POI ProcessRestaurant(string restLink)
        {
            //load restaurant page
            var restaurantPage = web.Load(tripadvisor + restLink);
            //find script containing JSON data about restaurant
            var contextScriptNode = restaurantPage.DocumentNode.SelectNodes("//script")[1];
            dynamic array = JsonConvert.DeserializeObject(contextScriptNode.InnerHtml);
            //create new POI and populate fields
            POI newPOI = new POI();
            newPOI.name = array["name"];
            newPOI.imgURL = array["image"];
            if (array["priceRange"] == "$$ - $$$")
            {
                newPOI.priceLevel = 2;
            }
            else if (array["PriceRange"] == "$$$$")
            {
                newPOI.priceLevel = 3;
            }
            else
            {
                newPOI.priceLevel = 1;
            }
            newPOI.avgRating = Convert.ToDouble(array["aggregateRating"]["ratingValue"]);
            newPOI.address = array["address"]["streetAddress"];
            newPOI.city = array["address"]["addressLocality"];

            //måske ændres
            var headerInfoNode = restaurantPage.GetElementbyId("taplc_resp_rr_top_info_rr_resp_0");
            newPOI.category = headerInfoNode.ChildNodes[0].ChildNodes[2].ChildNodes[2].ChildNodes[0].ChildNodes[2].InnerText;
            newPOI.openingshours = new Dictionary<string, List<string>>();


            driver.Navigate().GoToUrl(tripadvisor + restLink);

            //Opening hours

            var openingHoursButton = driver.FindElementsByXPath("//div[contains(@class,'hoursOpenerContainer')]")[0];
            openingHoursButton.Click();
            Thread.Sleep(5000);
            IWebElement openingHoursWindowContents = null;

            try
            {
                openingHoursWindowContents = driver.FindElementByXPath("//*[contains(@id,'c_popover_')]");
            }
            catch (Exception e)
            {
                Console.WriteLine("Opening times error");
            }
            
            var openingHours = openingHoursWindowContents.Text.Split('\n').Skip(1).ToList();

            int lastDayIndex = 0;
            for (int i = 0; i < openingHours.Count(); i++)
            {
                if (Char.IsNumber(openingHours[i].First()))
                {
                    newPOI.openingshours[openingHours[lastDayIndex]].Add(openingHours[i]);
                }
                else
                {
                    newPOI.openingshours.Add(openingHours[i], new List<string>());
                    lastDayIndex = i;
                }
            }

            return newPOI;
        }

        private void ProcessRestaurantReviews(POI newPOI, string restaurantLink)
        {

            newPOI.reviews = new List<Review>();
            //Review handling
            var noPages = 1;
            var alteredDoc = new HtmlDocument();

            
            driver.Navigate().GoToUrl(tripadvisor + restaurantLink);

            //Check language box for all languages
                                                              
            var languageCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[4]/div/div[2]/div[1]/div[1]/label");
            languageCheckBox.Click();
            Thread.Sleep(CLICK_WAIT);
            IWebElement tripCheckBox = null;
            for (int i = 0; i < 5; i++)
            {
                if (i == 0)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[1]");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    Console.WriteLine("-- Processing Family reviews :: " + DateTime.Now);
                    tripType = "family";
                }
                else if (i == 1)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[1]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[2]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    Console.WriteLine("-- Processing Couple reviews :: " + DateTime.Now);
                    tripType = "couple";
                }
                else if (i == 2)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[2]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[3]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    Console.WriteLine("-- Processing Alone reviews :: " + DateTime.Now);
                    tripType = "alone";
                }
                else if (i == 3)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[3]/label");

                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                                                              //*[@id="taplc_detail_filters_rr_resp_0"]/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[4]/label
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[4]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    Console.WriteLine("-- Processing Business reviews :: " + DateTime.Now);
                    tripType = "business";
                }
                else if (i == 4)
                {
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[4]/label");

                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    tripCheckBox = driver.FindElementByXPath("//*[@id='taplc_detail_filters_rr_resp_0']/div/div[1]/div/div[2]/div[2]/div/div[2]/div/div[5]/label");
                    tripCheckBox.Click();
                    Thread.Sleep(CLICK_WAIT);
                    Console.WriteLine("-- Processing Friends reviews :: " + DateTime.Now);
                    tripType = "friends";
                }

                alteredDoc.LoadHtml(driver.PageSource);
                //Find number of pages of reviews
                var pageNodes = alteredDoc.DocumentNode.SelectNodes("//a[contains(@class, 'pageNum last taLnk')]");
                if (pageNodes != null) noPages = Convert.ToInt32(pageNodes[0].InnerText);
                else noPages = 1;


                for (int h = 0; h < noPages; h++)
                {
                    if (h != 0)
                    {
                        var insIndex = restaurantLink.IndexOf("Reviews") + 8;
                        restaurantLink = restaurantLink.Insert(insIndex, "or" + h * 10 + "-");
                        driver.Navigate().GoToUrl(tripadvisor + restaurantLink);
                        alteredDoc.LoadHtml(driver.PageSource);
                    }

                    var reviewNodes = alteredDoc.DocumentNode.SelectNodes("//div[contains(@class,'rev_wrap')]");
                    if (reviewNodes == null) continue;


                    int k = 0;
                    foreach (var item in reviewNodes)
                    {
                        string userID = null;
                        try
                        {
                            userID = item.SelectNodes("//div[@class='member_info']")[k].ChildNodes[0].Id.Substring(4).Split('-')[0];
                        }
                        catch (Exception e)
                        {
                            Console.WriteLine("Invalid user found -> SKIPPING");
                            k++;
                            continue;
                        }
                        var newReview = new Review();
                        if (users.ContainsKey(userID))
                        {
                            //users[userID].given_reviews.Add(newReview.id);
                            newReview.author = users[userID];
                        }
                        else
                        {
                            var newUser = new User();
                            newUser.uid = userID;
                            users.Add(userID, newUser);
                            //newUser.given_reviews = new List<int>();
                            //newUser.given_reviews.Add(newReview.id);
                            newReview.author = newUser;
                        }
                        var rating = Char.GetNumericValue(item.ChildNodes[1].InnerHtml.Split('_')[3][0]);
                        newReview.rating = rating;
                        newReview.month_visited = item.SelectNodes("//div[@class='prw_rup prw_reviews_stay_date_hsx']")[k].InnerText.Split(':')[1].Trim();
                        newReview.company = tripType;

                        

                        newPOI.reviews.Add(newReview);
                        k++;

                    }
                    Console.WriteLine("Page: " + (h+1) + "/" + noPages);
                    Thread.Sleep(1000);
                }
                Console.WriteLine("Finished triptype: " + tripType + " :: " + DateTime.Now);
                Console.WriteLine();



            }
            Console.WriteLine(" ===== Finished processing:" + newPOI.name + " =====");
            Console.WriteLine();
            results.Add(newPOI);
        }

    }
}
