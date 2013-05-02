#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Smart::Comments;
use Mojo::UserAgent;

my $base_url = 'http://www.jxdyys.com';
my $ua = Mojo::UserAgent->new;

my $video_lists_dom = $ua->get($base_url)->res->dom;
my $video_lists_id = $video_lists_dom->find('html body div[class="video_list"][id]');

for my $list ($video_lists_id->each) {
    my $board = $list->[0]{tree}[2]{id};
    my ($hot, $new, $type, $location, $time, $rank);

    my $list_1 = $list->find('div.video_list_1 div[class]');
    for my $list_1f ($list_1->each) {
        $hot = $list_1f->find('div.video_list_1_img');
        $new = $list->find('div.video_list_1_text');
    }

    my $list_2 = $list->find('div.video_list_2');
    for my $list_2f ($list_2->each) {
        $type = "";
        $location = "";
        $time = "";
        $rank = "";
    }
    
    gain_info($new);
}

# pickout information from page
# information include: url image title actor 
sub gain_info {
    my $information = shift @_;
    my $temp;
    my $ua_next = Mojo::UserAgent->new;

    for my $item ($information->each) {
        # pick out links from page
        my $link_multi = $item->find('a');
        my @links = split /\n/,$link_multi;
        for my $link_single (@links) {
            $link_single =~ m/href="([^"]*)"/;
            $temp = $1;
            (not $temp=~ m/^http/) ? say $link_single = $base_url . $temp : say $link_single = $temp;
            my $item_dom = $ua_next->get($link_single)->res->dom;

            # pick out images from page
            my $img = $item_dom->find('div#video_detail_left_video_img img');
            $img =~ m/src="([^"]*)"/;
            $temp = $1;
            (not $temp=~ m/^http/) ? say $img = $base_url . $temp : say $temp;
            
            # pick out actors from page
            my $actor = $item_dom->find('div#video_detail_right p a')->pluck('text');
            say $actor;

            # pick out titles from page
            my $title = $item_dom->find('div#video_detail_right h1.vodeo_detail_right_title')->pluck('text');
            say $title;
        }
    }
}
