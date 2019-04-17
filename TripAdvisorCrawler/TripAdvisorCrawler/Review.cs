using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TripAdvisorCrawler
{
    public class Review
    {
        [BsonId]
        public int id;

        [BsonElement("rating")]
        public double rating;

        [BsonIgnore]
        public User author;

        [BsonElement("user_id")]
        public string user_id { get {return author.uid; } }

        [BsonIgnore]
        public POI subject;

        [BsonElement("poi_id")]
        public int subjectID { get { return subject.id; } }

        [BsonElement("month_visited")]
        public string month_visited;

        [BsonElement("company")]
        public string company;
    }
}
