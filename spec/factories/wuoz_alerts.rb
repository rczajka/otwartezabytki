# -*- encoding : utf-8 -*-
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :wuoz_alert do |f|
    f.wuoz_agency_id 1
    f.alert_id 1
    f.sent_at "2012-10-04 16:00:34"
  end
end
