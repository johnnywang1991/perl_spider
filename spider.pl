#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Smart::Comments;
use Mojo::UserAgent;
use encoding 'utf8' , STDIN => 'utf8', STDOUT => 'utf8';

my $baseurl = 'http://www.jxdyys.com';
my $ua = Mojo::UserAgent->new;
my $ua_next = Mojo::UserAgent->new;

my $video_lists_dom = $ua->get($baseurl)->res->dom;
my $video_lists_id = $video_lists_dom->find('html body div[class="video_list"][id]');

for my $list ($video_lists_id->each) {
    my $board = $list->[0]{tree}[2]{id}; #版块
    my ($hot, $new); #最热和最近更新 

    my $list_1 = $list->find('div.video_list_1 div[class]');
    for my $list_1f ($list_1->each) {
        $hot = $list_1f->find('div.video_list_1_img');
        $new = $list->find('div.video_list_1_text');

        gain_info($hot, $baseurl, $board);
        gain_info($new, $baseurl, $board);
    }
##
#     my $classify; #分类
#     my $temp_main; #临时变量
#     my $list_2 = $list->find('div.video_list_2');
#     for my $list_2f ($list_2->each) {
#         $classify = $list_2f->find('div.video_class');
#         for my $class ($classify->each) {
#             my $class_title = $class->find('h1')->pluck('text');
#             my $class_multi = $class->find('ul li a');
#             my @classes = split /\n/, $class_multi;
#             for my $class_single (@classes) {
#                 $class_single =~ m/href="([^"]*)"/;
#                 $temp_main = $1;
#                 (not $temp_main =~ m/^http/) ? ($class_single = $baseurl . $temp_main) : ($class_single = $temp_main);
#                 my $next_page_dom = $ua_next->get($class_single)->res->dom;
#                 my $next_page_link = $next_page_dom->find('div#video_channel_right ul li a');
#                 gain_info($next_page_link, $baseurl, $board);
#             }
#         }
#     }
##

}

# pickout information from page
# information include: url image title actor city language
sub gain_info {
    use DBI;
    my $database = 'site';
    my $hostname = 'localhost';
    my $user = 'root';
    my $password = 'redhat';
    my $dsn = "DBI:mysql:database=$database;host=$hostname";
    my $dbh = DBI->connect($dsn, $user, $password);

    my $page = shift @_;
    my $baseurl_info = shift @_;
    my $board_info = shift @_;
    my $ua_info = Mojo::UserAgent->new;
    my $temp_info;

    for my $item ($page->each) {
        # pick out urls from page
        my $url_multi = $item->find('a');
        my @urls = split /\n/,$url_multi;
        for my $url (@urls) {
            if ( $url =~ m/href="([^"]*)"/ ) {
                $temp_info = $1;
                (not $temp_info =~ m/^http/) ? ($url = $baseurl_info . $temp_info) : ($url = $temp_info);
                my $item_dom = $ua_info->get($url)->res->dom;

                # pick out images from page
                my $imgurl = $item_dom->find('div#video_detail_left_video_img img');
                $imgurl =~ m/src="([^"]*)"/;
                my $temp_info= $1;
                (not $temp_info=~ m/^http/) ? ($imgurl = $baseurl_info . $temp_info) : ($imgurl = $temp_info);
                
                # pick out actors from page
                my $protagonist_info = $item_dom->find('div#video_detail_right p a')->pluck('text');
                my @protagonists = split /\n/,$protagonist_info;
                my $protagonist = '';
                $protagonist .= "$_ " for @protagonists;

                # pick out title city language from page
                my $all_info = $item_dom->find('div.video_detail_left_info ul li span')->pluck('text');
                my @all_infos = split /\n/, $all_info;
                my $name = shift @all_infos;
                my $city = shift @all_infos;
                my $language = shift @all_infos;
                my $grade = $all_infos[1];
                ### $board_info
                ### $name
                ### $protagonist
                ### $city
                ### $language
                ### $grade
                ### $imgurl
                ### $url;
                my $rows = $dbh->do(
                    "INSERT INTO info VALUES ('',$board_info,$name,$protagonist,$city,$language,$grade,$imgurl,$url)"
                    # "INSERT INTO info VALUES ('','board_info','name','protagonist','city','language','grade','imgurl','url')"
                );
                say "$rows row(s) affected";
            }
        }
    }
}
