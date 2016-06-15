'use strict';

import React from 'react';

import ReactNative, {
  Text,
  View,
  Navigator,

} from 'react-native';

import BrokerList from './BrokerList';

module.exports = React.createClass({
  renderScene(route,navigator){
    return <BrokerList navigator={navigator} route={route} />;
  },
  render() {
    return (
      <Navigator
        initialRoute={{name:'BrokerList'}}
        renderScene={this.renderScene}
      />
    );
  },
});
