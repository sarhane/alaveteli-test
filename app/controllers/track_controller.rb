# app/controllers/track_controller.rb:
# Publically visible email alerts and RSS - think an alert system crossed with
# social bookmarking.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_controller.rb,v 1.5 2008-04-09 01:32:52 francis Exp $

require 'feedparser'

class TrackController < ApplicationController

    # Track all updates to a particular request
    def track_request
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        @track_thing = TrackThing.create_track_for_request(@info_request)
        ret = self.track_set
        if ret
            if @track_thing.track_medium == 'feed'
                redirect_to :controller => 'track', :action => 'atom_feed', :track_id => @track_thing.id
            else
                flash[:notice] = "You are " + ret + " tracking this request!"
                redirect_to request_url(@info_request)
            end
        end
    end

    # Generic request tracker - set @track_thing before calling
    def track_set
        if @user
            @existing_track = TrackThing.find_by_existing_track(@user.id, @track_thing.track_query)
            if @existing_track
                return "already"
            end
        end

        @track_thing.track_medium = 'email_daily'

        @title = @track_thing.params[:set_title]
        if params[:track_thing]
            @track_thing.track_medium = params[:track_thing][:track_medium]
        end

        if not params[:submitted_track] or not @track_thing.valid?
            render :template => 'track/track_set'
            return false
        end
        
        if not authenticated?(@track_thing.params)
            return false
        end

        @track_thing.tracking_user_id = @user.id
        @track_thing.save!

        return "now"
    end 

    # Atom feed (like RSS) for the track
    def atom_feed
        @track_thing = TrackThing.find(params[:track_id].to_i)

        perform_search(@track_thing.track_query, @track_thing.params[:feed_sortby], 25, 1) 
        respond_to :atom
    end

    # Delete a track
    def delete
        track_thing = TrackThing.find(params[:track_id].to_i)

        if not authenticated_as_user?(track_thing.tracking_user,
                :web => "To cancel this alert",
                :email => "Then you can cancel the alert.",
                :email_subject => "Cancel a WhatDoTheyKnow alert"
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        track_thing.destroy

        flash[:notice] = "Your alert has been cancelled."
        redirect_to user_url(track_thing.tracking_user)
    end

end
 