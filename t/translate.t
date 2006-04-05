use FEAR::API -base;


url("google.com");
fetch;
print document->as_string;