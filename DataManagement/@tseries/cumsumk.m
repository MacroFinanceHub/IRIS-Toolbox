function this = cumsumk(this, range, varargin)
% cumsumk  Cumulative sum with a k-period leap
%
% __Syntax__
%
%     Y = cumsumk(X, Range, ...)
%
%
% __Input Arguments__
%
% * `X` [ tseries ] - Input time series.
%
% * `Range` [ DateWrapper | Inf ] - Range on which the cumulative sum
% will be computed and the output time series returned, not including the
% presample or postsample needed.
%
%
% __Output Arguments__
%
% * `X` [ tseries ] - Output time series constructed as described below;
% the time series is returned for the `Range`, without the presample or
% postsample data used for initial or terminal condition.
%
%
% __Options__
%
% * `K=@auto` [ numeric | `@auto` ] - Number of periods that will be leapt
% the cumulative sum will be taken; `@auto` means `K` is chosen to match
% the frequency of the input series (e.g. `K=-4` for quarterly data), or
% `K=-1` for integer
% frequency.
%
% * `Log=false` [ `true` | `false` ] - Logarithmize the input data before, 
% and de-logarithmize the output data back afterwards.
%
% * `Rho=1` [ numeric ] - Autoregressive coefficient.
%
%
% __Description__
%
% If `K<0`, the first `K` observations in the output series are copied from
% the input series, and the new observations are given recursively by
%
%     Y{t} = Rho*Y{t-K} + X{t}.
%
% If `K>0`, the last `K` observations in the output series are copied from
% the input series, and the new observations are given recursively by
%
%     Y{t} = Rho*Y{t+K} + X{t}, 
%
% going backwards in time.
%
% If `K == 0`, the input data are returned.
%
% __Example__
%
% Construct random data with seasonal pattern, and run X12 to seasonally
% adjust these series.
%
%     x = tseries(qq(1990, 1):qq(2020, 4), @randn);
%     x1 = cumsumk(x, -4, 1);
%     x2 = cumsumk(x, -4, 0.7);
%     x1sa = x12(x1);
%     x2sa = x12(x2);
%
% The new series `x1` will be a unit-root process while `x2` will be
% stationary. Note that the command on the second line could be replaced
% with `x1 = cumsumk(x)`.
%

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2018 IRIS Solutions Team

persistent parser
if isempty(parser)
    parser = extend.InputParser('tseries.cumsumk');
    parser.addRequired('TimeSeries', @(x) isa(x, 'tseries'));
    parser.addRequired('Range', @DateWrapper.validateProperRangeInput);
    parser.addParameter('K', @auto, @(x) isequal(x, @auto) || (isnumeric(x) && isscalar(x) && x==round(x)));
    parser.addParameter('Rho', 1, @(x) isnumeric(x) && isscalar(x));
    parser.addParameter('Log', false, @(x) islogical(x) && isscalar(x));
    parser.addParameter('NaNInit', 0, @isnumeric);
end
parser.parse(this, range, varargin{:});
opt = parser.Options;

if isequal(opt.K, @auto)
    freqOfInput = DateWrapper.getFrequencyAsNumeric(this.Start);
    opt.K = -max(1, freqOfInput);
end

if opt.K==0
    return
end

if ~isa(range, 'DateWrapper')
    range = DateWrapper.fromDateCode(range);
end

%--------------------------------------------------------------------------

start = range(1);
extendedStart = addTo(start, min(0, opt.K));
extendedEnd = addTo(getLast(range), max(0, opt.K));
data = getDataFromTo(this, extendedStart, extendedEnd);

sizeData = size(data);
ndimsData = ndims(data);
data = data(:, :);

if opt.Log
    data = log(data);
end

data = numeric.cumsumk(data, opt.K, opt.Rho, opt.NaNInit);

if opt.Log
    data = exp(data);
end

this.Start = start;
if ndimsData>2
    sizeData(1) = size(data, 1);
    data = reshape(data, sizeData);
end
this.Data = data;

this = trim(this);

end
