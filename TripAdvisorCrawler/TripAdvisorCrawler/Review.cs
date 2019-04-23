using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TripAdvisorCrawler
{
    public class Review
    {
        public int id;

        public double rating;

        public User author;

        public string user_id { get {return author.uid; } }

        public POI subject;

        public int subjectID { get { return subject.id; } }

        public string month_visited;

        public string company;
    }
}
