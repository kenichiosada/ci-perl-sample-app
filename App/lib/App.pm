package App;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    return 1;
};

get '/test' => sub {
    return 1;
};


true;
