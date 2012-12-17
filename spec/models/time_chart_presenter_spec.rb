require 'spec_helper'

describe TimeChartPresenter do

  def row_values(rows, num)
    rows[num].map { |c| c.v }
  end

  before :each do
    @sample_stories = [
        double(# -> Story is done and belongs to an old iteration
            :id => 1,
            :name => "story1",
            :story_type => Story::FEATURE,
            :created_at => DateTime.parse("2011-12-01 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-12 11:02:00 UTC"),
            :current_state => "accepted",
            :accepted_at => DateTime.parse("2012-01-12 11:02:00 UTC"),
            #:estimate => 1,        Estimate is missing
            :accepted? => true,
            :activities => [# Time spent on this story --> 1d / 8 hrs --> 0 left over from previous iteration
                double(
                    :occurred_at => DateTime.parse("2011-12-01 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2011-12-02 10:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2011-12-03 10:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2011-12-04 10:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "delivered"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 11:02:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "accepted"
                                 )]
                )
            ]
        ),
        double(
            :id => 2,
            :name => "story2",
            :story_type => Story::FEATURE,
            :created_at => DateTime.parse("2012-01-01 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-13 15:01:00 UTC"),
            :current_state => "accepted",
            :accepted_at => DateTime.parse("2012-01-13 15:01:00 UTC"),
            :estimate => 2,
            :labels => "feature1,backend,showroom,ios,filter1",
            :accepted? => true,
            :activities => [# Time spent on this story --> 7 hrs / 7 hrs
                double(
                    :occurred_at => DateTime.parse("2012-01-01 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 07:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk started the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(         # story is updated, but story state is not changed
                    :occurred_at => DateTime.parse("2012-01-11 09:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk &quot;Divert power from warp coils&quot;",
                    :stories => [double(
                                     :current_name => "new name"
                                 )]
                ),
                double(         # story is updated, but story state is not changed
                    :occurred_at => DateTime.parse("2012-01-11 10:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk estimated &quot;Divert power from warp coils&quot; as 3 points",
                    :stories => [double(
                                     :current_name => "new name"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 14:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk finished the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 14:10:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk delivered the story",
                    :stories => [double(
                                     :current_state => "delivered"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-13 15:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk accepted the story",
                    :stories => [double(
                                     :current_state => "accepted"
                                 )]
                )
            ]
        ),
        double(
            :id => 3,
            :name => "story3",
            :story_type => Story::FEATURE,
            :created_at => DateTime.parse("2011-12-25 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-12 13:02:00 UTC"),
            :current_state => "delivered",
            :estimate => 3,
            :labels => "feature1,backend,showroom,ios,aiq8",
            :accepted? => false,
            :activities => [# Time spent on this story --> 1d / 8 hrs
                double(
                    :occurred_at => DateTime.parse("2011-12-25 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 11:02:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 11:02:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 13:02:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "delivered"
                                 )]
                )
            ]
        ),
        double(
            :id => 4,
            :name => "story4",
            :story_type => Story::FEATURE,
            :created_at => DateTime.parse("2012-01-03 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-12 13:02:00 UTC"),
            :current_state => "rejected",
            :labels => "feature2,backend",
            :estimate => 4,
            :accepted? => false,
            :activities => [# Time spent on this story --> 4 hrs
                double(
                    :occurred_at => DateTime.parse("2012-01-03 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 15:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 15:02:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "delivered"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 13:02:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "rejected"
                                 )]
                )
            ]
        ),
        double(
            :id => 5,
            :name => "story5",
            :story_type => Story::CHORE,
            :created_at => DateTime.parse("2012-01-04 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-16 15:00:00 UTC"),
            :current_state => "finished",
            :labels => "feature3,backend,filter1",
            :accepted? => false,
            :activities => [# Time spent on this story -->  3d 4h + 4h - 2d(weekend)  = 16
                double(
                    :occurred_at => DateTime.parse("2012-01-04 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 15:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unstarted"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-13 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-16 15:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                )
            ]

        ),
        double(
            :id => 6,
            :name => "story6",
            :story_type => Story::BUG,
            :created_at => DateTime.parse("2012-01-05 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-16 10:00:00 UTC"),
            :current_state => "started", #
            :labels => "feature3,android",
            :accepted? => false,
            :activities => [# Time spent on this story -->  1d / 8h
                double(
                    :occurred_at => DateTime.parse("2012-01-05 10:00:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-16 10:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                )
            ]
        ),
        double(
            :id => 7,
            :name => "story7",
            :story_type => Story::FEATURE,
            :created_at => DateTime.parse("2012-01-11 10:01:00 UTC"), # -> impediment
            :updated_at => DateTime.parse("2012-01-13 15:01:00 UTC"),
            :current_state => "accepted",
            :accepted_at => DateTime.parse("2012-01-13 15:01:00 UTC"),
            :labels => "feature3,ios",
            :estimate => 5,
            :accepted? => true,
            :activities => [# Time spent on this story --> 4 hrs / 4 hrs
                double(
                    :occurred_at => DateTime.parse("2012-01-11 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 07:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk started the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(         # story is updated, but story state is not changed
                    :occurred_at => DateTime.parse("2012-01-12 09:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk edited &quot;Divert power from warp coils&quot;",
                    :stories => [double(
                                     :current_name => "new name"
                                 )]
                ),
                double(         # story is updated, but story state is not changed
                    :occurred_at => DateTime.parse("2012-01-12 10:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk estimated &quot;Divert power from warp coils&quot; as 3 points",
                    :stories => [double(
                                     :current_name => "new name"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 11:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk finished the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 14:10:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk delivered the story",
                    :stories => [double(
                                     :current_state => "delivered"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-13 15:01:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk accepted the story",
                    :stories => [double(
                                     :current_state => "accepted"
                                 )]
                )
            ]
        ),
        double(
            :id => 8,
            :name => "story8",

            :story_type => Story::CHORE,
            :created_at => DateTime.parse("2012-01-16 10:00:00 UTC"), # -> impediment
            :updated_at => DateTime.parse("2012-01-16 16:00:00 UTC"),
            :current_state => "started",
            :accepted? => false,
            :activities => [# Time spent on this story -->  18h --> 2h
                double(
                    :occurred_at => DateTime.parse("2012-01-16 10:00:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-16 16:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                )
            ]
        ),
        double(
            :id => 9,
            :name => "story9",

            :story_type => Story::BUG,
            :created_at => DateTime.parse("2012-01-14 10:01:00 UTC"), # -> impediment
            :updated_at => DateTime.parse("2012-01-17 09:00:00 UTC"),
            :current_state => "unstarted", #
            :labels => "opera,filter1",
            :accepted? => false,
            :activities => [# Time spent on this story -->  1d 6h  = 14h
                double(
                    :occurred_at => DateTime.parse("2012-01-14 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-15 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-17 09:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unstarted"
                                 )]
                )
            ]
        ),
        double(
            :id => 10,
            :name => "story10",
            :story_type => Story::CHORE,
            :created_at => DateTime.parse("2012-01-04 10:01:00 UTC"), # -> planned
            :updated_at => DateTime.parse("2012-01-11 11:00:00 UTC"),
            :current_state => "finished",
            :accepted? => false,
            :activities => [# Time spent on this story --> 4 + 24 = 28 , but 12 (8 + 4) since some work is done before the start time.
                            # In which case, we calculate from the start date at 9:00(7:00 UTC)
                double(
                    :occurred_at => DateTime.parse("2012-01-04 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-06 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-06 15:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unstarted"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-08 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-11 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                )
            ]

        ),
        double(
            :id => 11,
            :name => "story11",

            :story_type => Story::BUG,
            :created_at => DateTime.parse("2012-01-14 10:01:00 UTC"), # -> impediment
            :updated_at => DateTime.parse("2012-01-22 13:00:00 UTC"),
            :current_state => "accepted",
            :accepted_at => DateTime.parse("2012-01-22 13:00:00 UTC"),
            :accepted? => true,
            :activities => [# Time spent on this story -->  1d 6h + 2h = 16h ---> 5h
                            # 14 is changed to 5 because some work is done after the end date. we measure until last day at 18:00 (16 utc)
                double(
                    :occurred_at => DateTime.parse("2012-01-14 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-20 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-22 09:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unstarted"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-22 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-22 13:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-22 13:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "accepted"
                                 )]
                )
            ]
        ) ,
        double(
            :id => 12,
            :name => "story12",

            :story_type => Story::BUG,
            :created_at => DateTime.parse("2012-01-14 10:01:00 UTC"), # -> impediment
            :updated_at => DateTime.parse("2012-01-17 09:00:00 UTC"),
            :current_state => "unstarted", #
            :labels => "opera,filter1",
            :accepted? => false,
            :activities => [# Time spent on this story -->  1d 6h  = 14h
                double(
                    :occurred_at => DateTime.parse("2012-01-14 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-17 09:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unstarted"
                                 )]
                )
            ]
        ),

        # ICEBOX
        double(
            :id => 19,
            :name => "story19",
            :story_type => Story::FEATURE,
            :created_at => DateTime.parse("2012-01-12 00:01:00 UTC"),
            :updated_at => DateTime.parse("2012-01-17 09:00:00 UTC"),
            :current_state => "unscheduled",
            :estimate => 6,
            :accepted? => false,
            :activities => [# Time spent on this story -->  0 because Story is in icebox
                double(
                    :occurred_at => DateTime.parse("2012-01-14 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-15 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-17 09:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unscheduled"
                                 )]
                )
            ]
        ),


        # BACKLOG
        double(
            :id => 20,
            :name => "story20",
            :story_type => Story::BUG,
            :created_at => DateTime.parse("2012-01-01 00:01:00 UTC"),
            :updated_at => DateTime.parse("2012-01-16 15:00:00 UTC"),
            :current_state => "unstarted",
            :accepted? => false,
            :activities => [# Time spent on this story -->  0 because Story is in backlog
                double(
                    :occurred_at => DateTime.parse("2012-01-04 10:01:00 UTC"),
                    :event_type => "story_create",
                    :description => "James Kirk created the story",
                    :stories => [double(:current_state => "unscheduled")]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-12 15:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "unstarted"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-13 11:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "started"
                                 )]
                ),
                double(
                    :occurred_at => DateTime.parse("2012-01-16 15:00:00 UTC"),
                    :event_type => "story_update",
                    :description => "James Kirk created the story",
                    :stories => [double(
                                     :current_state => "finished"
                                 )]
                )
            ]
        )
    ]


    stories = double("project stories")
    stories.stub(:all).and_return(@sample_stories)

    @iterations = [
        double(
            :number => 1,
            :start_date => Date.parse("2012-01-01 22:00:00 UTC"),
            :finish_date => Date.parse("2012-01-10 22:00:00 UTC"),
            :stories => []),
        double(
            :number => 2,
            :start_date => Date.parse("2012-01-10 22:00:00 UTC"),
            :finish_date => Date.parse("2012-01-20 22:00:00 UTC"),
            :stories => []),
        double(
            :number => 3,
            :start_date => Date.parse("2012-01-20 22:00:00 UTC"),
            :finish_date => Date.parse("2012-01-30 22:00:00 UTC"),
            :stories => []),
        double(
            :number => 4,
            :start_date => Date.parse("2012-01-30 22:00:00 UTC"),
            :finish_date => Date.parse("2012-02-10 22:00:00 UTC"),
            :stories => [])
    ]

    @iterations[0].stories << @sample_stories[0]
    @iterations[1].stories << @sample_stories[1]
    @iterations[1].stories << @sample_stories[2]
    @iterations[1].stories << @sample_stories[3]
    @iterations[1].stories << @sample_stories[4]
    @iterations[1].stories << @sample_stories[5]
    @iterations[1].stories << @sample_stories[6]
    @iterations[1].stories << @sample_stories[7]
    @iterations[1].stories << @sample_stories[8]
    @iterations[1].stories << @sample_stories[9]
    @iterations[1].stories << @sample_stories[10]
    @iterations[1].stories << @sample_stories[11]
    @iterations[2].stories << @sample_stories[12]
    @iterations[2].stories << @sample_stories[13]

    Time.stub!(:now).and_return(Time.utc(2012, 01, 17, 10, 00, 00))
  end

  describe "current iteration" do

    it "should return current iteration if the date range is not specified" do

      chart_presenter = TimeChartPresenter.new(@iterations, @sample_stories)
      current_iteration = chart_presenter.current_iteration

      current_iteration.number.should == 2
    end

    it "should return current iteration even if the date range is specified" do

      chart_presenter = TimeChartPresenter.new(@iterations,
                                               @sample_stories,
                                               DateTime.parse("2012-01-07 00:01:00 UTC"),
                                               DateTime.parse("2012-02-07 00:01:00 UTC"))
      current_iteration = chart_presenter.current_iteration

      current_iteration.number.should == 2
    end

  end

  describe "active iterations" do
    it "should return zero iterations for active date range before the first iteration" do
      chart_presenter = TimeChartPresenter.new(@iterations,
                                               @sample_stories,
                                               DateTime.parse("2010-01-17 00:01:00 UTC"),
                                               DateTime.parse("2010-01-23 00:02:00 UTC"))
      active_iterations = chart_presenter.active_iterations

      active_iterations.length.should == 0
    end

    it "should return zero iterations for active date range after the last iteration" do
      # Case #4
      chart_presenter = TimeChartPresenter.new(@iterations,
                                               @sample_stories,
                                               DateTime.parse("2012-02-07 00:01:00 UTC"),
                                               DateTime.parse("2012-02-23 00:02:00 UTC"))
      active_iterations = chart_presenter.active_iterations

      active_iterations.length.should == 0
    end

    it "should return only current iteration if the date range is not specified" do
      expected_first_iteration_nr = @iterations[1].number
      expected_last_iteration_nr = @iterations[1].number


      chart_presenter = TimeChartPresenter.new(@iterations, @sample_stories)
      active_iterations = chart_presenter.active_iterations

      active_iterations.length.should == 1

      active_iterations.first.number.should == expected_first_iteration_nr
      active_iterations.last.number.should == expected_last_iteration_nr
    end

    it "should return iterations starting after start date and ending before end date" do
      expected_first_iteration_nr = @iterations[1].number
      expected_last_iteration_nr = @iterations[2].number


      chart_presenter = TimeChartPresenter.new(@iterations,
                                               @sample_stories,
                                               DateTime.parse("2012-01-07 00:01:00 UTC"),
                                               DateTime.parse("2012-02-07 00:01:00 UTC"))
      active_iterations = chart_presenter.active_iterations

      active_iterations.length.should == 2

      active_iterations.first.number.should == expected_first_iteration_nr
      active_iterations.last.number.should == expected_last_iteration_nr
    end

  end

  describe "active stories" do
    it "should return all stories updated during the given date range" do
      chart_presenter = TimeChartPresenter.new(@iterations,
                                               @sample_stories,
                                               DateTime.parse("2012-01-13 00:01:00 UTC"),
                                               DateTime.parse("2012-01-20 00:01:00 UTC"))
      active_stories = chart_presenter.active_stories

      active_stories.length.should == 7
    end

    it "should exclude the stories which are accepted before the given date range" do
      chart_presenter = TimeChartPresenter.new(@iterations,
                                               @sample_stories,
                                               DateTime.parse("2012-01-10 00:01:00 UTC"),
                                               DateTime.parse("2012-01-13 00:01:00 UTC"))
      active_stories = chart_presenter.active_stories

      active_stories.length.should == 8
    end

  end

  context "time charts" do
    let(:chart) { @chart_presenter.send(chart_method, params.blank? ? {}: params) }

    before do
      @chart_presenter = TimeChartPresenter.new(@iterations, @sample_stories, Date.parse("2012-01-10"), Date.parse("2012-01-20"))
    end

    describe "#story_types_time_chart" do
      let(:params){{types:Story::ALL_STORY_TYPES }}
      let(:chart_method) { "story_types_time_chart" }

      it "produces a chart" do
        rows = chart.data_table.rows

        row_values(rows, 0).should == ["Features", 23] # 7 + 8 + 4 + 4
        row_values(rows, 1).should == ["Bugs", 22]     # 8 + 14
        row_values(rows, 2).should == ["Chores", 30]   # 16 + 2 + 12

      end
    end

    describe "#story_types_time_chart_filters" do
      let(:params){{types:Story::ALL_STORY_TYPES ,filters:["filter1"]}}
      let(:chart_method) { "story_types_time_chart" }

      #it_should_behave_like "a chart generation method"

      it "produces a chart" do
        rows = chart.data_table.rows

        row_values(rows, 0).should == ["Features", 7] # 7
        row_values(rows, 1).should == ["Bugs", 14]     # 14
        row_values(rows, 2).should == ["Chores", 16]   # 16

      end
    end

    describe "#features_time_chart" do
      let(:params){{types:Story::ALL_STORY_TYPES ,features:["feature1", "feature2", "feature3"]}}
      let(:chart_method) { "features_time_chart" }

      it "produces a chart" do
        rows = chart.data_table.rows

        row_values(rows, 0).should == ["feature1", 15]  # 7 + 8
        row_values(rows, 1).should == ["feature2", 4]  # 4
        row_values(rows, 2).should == ["feature3", 28]  # 16 + 8 + 4

      end
    end

    describe "#impediments_time_chart" do
      let(:params){{types:Story::ALL_STORY_TYPES}}
      let(:chart_method) { "impediments_time_chart" }

      it "produces a chart" do
        rows = chart.data_table.rows

        row_values(rows, 0).should == ["Unplanned", 20]   # 4 + 2 + 14
        row_values(rows, 1).should == ["Planned", 55]     # 4 + 7 + 8 + 16 + 8 + 12

      end
    end

    describe "#story_details_table" do
      let(:params){{types:Story::ALL_STORY_TYPES ,filters:["filter1"]}}
      let(:chart_method) { "story_details_table" }

      it "produces a chart" do
        rows = chart.data_table.rows

        rows.length.should ==  4
        row_values(rows, 0).should == ["20120113","<a href='https://www.pivotaltracker.com/story/show/2'>story2</a>", "accepted", "", "backend,ios", true, 8, 7, -13]
        row_values(rows, 1).should == ["","<a href='https://www.pivotaltracker.com/story/show/5'>story5</a>", "finished", "", "backend",true, 0, 16, 0]
        row_values(rows, 2).should == ["","<a href='https://www.pivotaltracker.com/story/show/9'>story9</a>", "paused", "", "",false, 0, 14, 0]
        row_values(rows, 3).should == ["","Total", "", "", "",true, 8, 37, -5]

      end
    end

  end
end