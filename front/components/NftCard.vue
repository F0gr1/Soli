<template>
    <v-container >
            <v-col cols='6'>
                <div class='d-flex' v-for="item in items">
                    <div class="card bg-info" style="width: 18rem;">
                        <div class="card-body">
                            <div class="d-flex ">
                                <h5 class="card-title text-left col">{{item}}</h5>
                                <h5 class="text-white col">￥100</h5>
                            </div>
                            <button class='submit'>　購入</button>
                        </div>
                    </div>
                </div>
            </v-col>
    </v-container>
</template>
<script>
export default {
 props: ['items']
}
</script>